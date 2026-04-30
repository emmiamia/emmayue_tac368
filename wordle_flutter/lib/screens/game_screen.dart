import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../l10n/app_localizations.dart';

import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';
import '../bloc/game_state.dart';
import '../data/word_list.dart';
import '../data/word_repository.dart';
import '../locale/locale_cubit.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../theme/theme_cubit.dart';
import '../widgets/board/board_widget.dart';
import '../widgets/hangman/hangman_widget.dart';
import '../widgets/dialogs/lose_dialog.dart';
import '../widgets/dialogs/win_dialog.dart';
import '../widgets/keyboard/keyboard_widget.dart';
import 'stats_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({
    super.key,
    required this.storageService,
    required this.wordList,
    required this.wordRepository,
    required this.soundService,
  });

  final StorageService storageService;
  final WordList wordList;
  final WordRepository wordRepository;
  final SoundService soundService;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GameBloc(
        wordRepository: wordRepository,
        wordList: wordList,
        storageService: storageService,
        soundService: soundService,
      )..add(const GameInitialize()),
      child: _GameView(storageService: storageService),
    );
  }
}

class _GameView extends StatelessWidget {
  const _GameView({required this.storageService});

  final StorageService storageService;

  void _startNewGame(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    }
    context.read<GameBloc>().add(const GameReset());
  }

  Future<void> _confirmRevealForfeit(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final loc = MaterialLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.revealForfeitTitle),
        content: Text(l10n.revealForfeitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.revealAnswer),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      context.read<GameBloc>().add(const GameRevealForfeit());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MultiBlocListener(
      listeners: [
        BlocListener<GameBloc, GameState>(
          listenWhen: (p, c) => c is GamePlaying && (c as GamePlaying).snackbarKey != null,
          listener: (ctx, state) {
            final s = state as GamePlaying;
            final key = s.snackbarKey;
            if (key == null) return;
            final loc = AppLocalizations.of(ctx)!;
            final text = switch (key) {
              'not_enough' => loc.messageNotEnoughLetters,
              'not_in_list' => loc.messageNotInWordList,
              _ => key,
            };
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(text)));
            ctx.read<GameBloc>().add(const GameDismissMessage());
          },
        ),
        BlocListener<GameBloc, GameState>(
          listenWhen: (p, c) => c is GameWon || c is GameLost,
          listener: (ctx, state) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!ctx.mounted) return;
              if (state is GameWon) showWinDialog(ctx, state);
              if (state is GameLost) showLoseDialog(ctx, state);
            });
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle),
          actions: [
            IconButton(
              tooltip: l10n.toggleTheme,
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              onPressed: () => context.read<ThemeCubit>().toggle(),
            ),
            Tooltip(
              message: l10n.language,
              child: PopupMenuButton<int>(
                onSelected: (v) {
                  if (v == 0) context.read<LocaleCubit>().useEnglish();
                  if (v == 1) context.read<LocaleCubit>().useChinese();
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(value: 0, child: Text(l10n.languageEnglish)),
                  PopupMenuItem(value: 1, child: Text(l10n.languageChinese)),
                ],
                child: const Icon(Icons.language),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StatsScreen(storage: storageService),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: l10n.revealAnswer,
              icon: const Icon(Icons.visibility_outlined),
              onPressed: () => _confirmRevealForfeit(context),
            ),
            TextButton(
              onPressed: () => _startNewGame(context),
              child: Text(l10n.newGame),
            ),
          ],
        ),
        body: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            final logical = event.logicalKey;
            if (logical == LogicalKeyboardKey.enter) {
              context.read<GameBloc>().add(const WordSubmitted());
              return KeyEventResult.handled;
            }
            if (logical == LogicalKeyboardKey.backspace) {
              context.read<GameBloc>().add(const BackspacePressed());
              return KeyEventResult.handled;
            }
            final ch = event.character;
            if (ch != null && ch.isNotEmpty) {
              final u = ch.toUpperCase();
              if (u.length == 1 && u.codeUnitAt(0) >= 65 && u.codeUnitAt(0) <= 90) {
                context.read<GameBloc>().add(LetterEntered(u));
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BlocBuilder<GameBloc, GameState>(
              builder: (context, state) {
                if (state is GameLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final gameplay = switch (state) {
                  GamePlaying(:final gameplay) => gameplay,
                  GameWon(:final gameplay) => gameplay,
                  GameLost(:final gameplay) => gameplay,
                  _ => null,
                };

                if (gameplay == null) {
                  return const SizedBox.shrink();
                }

                final (shakeVersion, shakeRow) = switch (state) {
                  GamePlaying(:final shakeVersion, :final shakeRow) => (shakeVersion, shakeRow),
                  _ => (0, -1),
                };

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final board = ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: BoardWidget(
                        gameplay: gameplay,
                        shakeVersion: shakeVersion,
                        shakeRow: shakeRow,
                      ),
                    );
                    final stage = hangmanStageFromGameplay(gameplay);
                    final keyboard = const KeyboardWidget();
                    final hangman = HangmanWidget(stage: stage);

                    final useSideBySide = constraints.maxWidth >= 560;
                    if (!useSideBySide) {
                      return Column(
                        children: [
                          Center(child: hangman),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Center(child: board),
                          ),
                          const SizedBox(height: 8),
                          Center(child: keyboard),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Center(child: board),
                        ),
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
                        ),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 340),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  hangman,
                                  const SizedBox(height: 16),
                                  const Spacer(),
                                  keyboard,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
