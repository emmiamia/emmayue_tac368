import 'package:equatable/equatable.dart';

sealed class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

final class GameInitialize extends GameEvent {
  const GameInitialize();
}

final class LetterEntered extends GameEvent {
  const LetterEntered(this.letter);

  final String letter;

  @override
  List<Object?> get props => [letter];
}

final class BackspacePressed extends GameEvent {
  const BackspacePressed();
}

final class WordSubmitted extends GameEvent {
  const WordSubmitted();
}

final class GameReset extends GameEvent {
  const GameReset();
}

final class GameDismissMessage extends GameEvent {
  const GameDismissMessage();
}

/// Shows the secret on the current row and ends the game as a loss.
final class GameRevealForfeit extends GameEvent {
  const GameRevealForfeit();
}
