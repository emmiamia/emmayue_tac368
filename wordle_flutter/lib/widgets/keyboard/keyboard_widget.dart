import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/game_bloc.dart';
import '../../bloc/game_event.dart';
import '../../bloc/game_state.dart';
import '../../models/letter_state.dart';
import 'key_widget.dart';

class KeyboardWidget extends StatelessWidget {
  const KeyboardWidget({super.key});

  static const _rows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(
      builder: (context, state) {
        final keys = switch (state) {
          GamePlaying(:final gameplay) => gameplay.keyboardStates,
          GameWon(:final gameplay) => gameplay.keyboardStates,
          GameLost(:final gameplay) => gameplay.keyboardStates,
          _ => const <String, LetterState>{},
        };

        LetterState st(String ch) => keys[ch] ?? LetterState.empty;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                for (final ch in _rows[0])
                  KeyWidget(
                    label: ch,
                    flex: 1,
                    state: st(ch),
                    onTap: () => context.read<GameBloc>().add(LetterEntered(ch)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(flex: 1),
                for (final ch in _rows[1])
                  KeyWidget(
                    label: ch,
                    flex: 1,
                    state: st(ch),
                    onTap: () => context.read<GameBloc>().add(LetterEntered(ch)),
                  ),
                const Spacer(flex: 1),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                KeyWidget(
                  label: 'ENTER',
                  flex: 2,
                  wide: true,
                  state: LetterState.empty,
                  onTap: () => context.read<GameBloc>().add(const WordSubmitted()),
                ),
                for (final ch in _rows[2])
                  KeyWidget(
                    label: ch,
                    flex: 1,
                    state: st(ch),
                    onTap: () => context.read<GameBloc>().add(LetterEntered(ch)),
                  ),
                KeyWidget(
                  label: '⌫',
                  flex: 2,
                  wide: true,
                  state: LetterState.empty,
                  onTap: () => context.read<GameBloc>().add(const BackspacePressed()),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
