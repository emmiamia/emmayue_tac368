import 'package:equatable/equatable.dart';

import 'letter_state.dart';
import 'tile.dart';

/// Domain snapshot of an in-progress or finished board (not the BLoC UI state).
class GameplayModel extends Equatable {
  const GameplayModel({
    required this.board,
    required this.currentRow,
    required this.currentColumn,
    required this.secretWord,
    required this.keyboardStates,
    this.hasWon = false,
    this.hasLost = false,
    this.streak = 0,
  });

  final List<List<Tile>> board;
  final int currentRow;
  final int currentColumn;
  final String secretWord;
  final Map<String, LetterState> keyboardStates;
  final bool hasWon;
  final bool hasLost;
  final int streak;

  GameplayModel copyWith({
    List<List<Tile>>? board,
    int? currentRow,
    int? currentColumn,
    String? secretWord,
    Map<String, LetterState>? keyboardStates,
    bool? hasWon,
    bool? hasLost,
    int? streak,
  }) {
    return GameplayModel(
      board: board ?? this.board,
      currentRow: currentRow ?? this.currentRow,
      currentColumn: currentColumn ?? this.currentColumn,
      secretWord: secretWord ?? this.secretWord,
      keyboardStates: keyboardStates ?? this.keyboardStates,
      hasWon: hasWon ?? this.hasWon,
      hasLost: hasLost ?? this.hasLost,
      streak: streak ?? this.streak,
    );
  }

  @override
  List<Object?> get props => [
        board,
        currentRow,
        currentColumn,
        secretWord,
        keyboardStates,
        hasWon,
        hasLost,
        streak,
      ];
}
