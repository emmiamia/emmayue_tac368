import 'package:equatable/equatable.dart';

import '../models/game_state.dart' as domain;

sealed class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

final class GameLoading extends GameState {
  const GameLoading();
}

final class GamePlaying extends GameState {
  const GamePlaying({
    required this.gameplay,
    this.snackbarKey,
    this.shakeVersion = 0,
    this.shakeRow = -1,
    this.revealingRow,
  });

  final domain.GameplayModel gameplay;
  /// `not_enough` | `not_in_list` — mapped to l10n in UI.
  final String? snackbarKey;
  /// Incremented when the current row should play the invalid-word shake.
  final int shakeVersion;
  final int shakeRow;
  final int? revealingRow;

  GamePlaying copyWith({
    domain.GameplayModel? gameplay,
    String? snackbarKey,
    int? shakeVersion,
    int? shakeRow,
    int? revealingRow,
    bool clearSnackbar = false,
  }) {
    return GamePlaying(
      gameplay: gameplay ?? this.gameplay,
      snackbarKey: clearSnackbar ? null : (snackbarKey ?? this.snackbarKey),
      shakeVersion: shakeVersion ?? this.shakeVersion,
      shakeRow: shakeRow ?? this.shakeRow,
      revealingRow: revealingRow ?? this.revealingRow,
    );
  }

  @override
  List<Object?> get props => [gameplay, snackbarKey, shakeVersion, shakeRow, revealingRow];
}

final class GameWon extends GameState {
  const GameWon({required this.gameplay, required this.guessCount});

  final domain.GameplayModel gameplay;
  final int guessCount;

  @override
  List<Object?> get props => [gameplay, guessCount];
}

final class GameLost extends GameState {
  const GameLost({required this.gameplay});

  final domain.GameplayModel gameplay;

  @override
  List<Object?> get props => [gameplay];
}
