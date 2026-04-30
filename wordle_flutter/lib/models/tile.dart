import 'package:equatable/equatable.dart';

import 'letter_state.dart';

class Tile extends Equatable {
  const Tile({
    this.letter = '',
    this.state = LetterState.empty,
  });

  final String letter;
  final LetterState state;

  bool get isEmpty => letter.isEmpty;

  Tile copyWith({
    String? letter,
    LetterState? state,
  }) {
    return Tile(
      letter: letter ?? this.letter,
      state: state ?? this.state,
    );
  }

  @override
  List<Object?> get props => [letter, state];
}
