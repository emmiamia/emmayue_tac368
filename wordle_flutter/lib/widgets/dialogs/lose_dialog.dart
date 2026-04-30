import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/app_localizations.dart';

import '../../bloc/game_bloc.dart';
import '../../bloc/game_event.dart';
import '../../bloc/game_state.dart';

Future<void> showLoseDialog(BuildContext context, GameLost state) {
  final bloc = context.read<GameBloc>();
  final l10n = AppLocalizations.of(context)!;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        title: Text(l10n.loseDialogTitle),
        content: Text(l10n.loseDialogBody(state.gameplay.secretWord)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              bloc.add(const GameReset());
            },
            child: Text(l10n.playAgain),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.close),
          ),
        ],
      );
    },
  );
}
