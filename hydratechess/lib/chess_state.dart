// chess_state.dart
// Barrett Koster 2025
// Hydration added

import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'coords.dart';

class ChessState {
  final List<List<String>> board;
  final int turnCount;

  ChessState({
    List<List<String>>? board,
    int turnCount = 0,
  })  : board = board ??
            [
              ['r.', 'p', ' ', ' ', ' ', ' ', 'P', 'R.'],
              ['n', 'p', ' ', ' ', ' ', ' ', 'P', 'N'],
              ['b', 'p', ' ', ' ', ' ', ' ', 'P', 'B'],
              ['q', 'p', ' ', ' ', ' ', ' ', 'P', 'Q'],
              ['k', 'p', ' ', ' ', ' ', ' ', 'P', 'K'],
              ['b', 'p', ' ', ' ', ' ', ' ', 'P', 'B'],
              ['n', 'p', ' ', ' ', ' ', ' ', 'P', 'N'],
              ['r.', 'p', ' ', ' ', ' ', ' ', 'P', 'R.'],
            ],
        turnCount = turnCount;

  ChessState copyWith({List<List<String>>? board, int? turnCount}) {
    return ChessState(
      board: board ?? this.board,
      turnCount: turnCount ?? this.turnCount,
    );
  }
}

class ChessCubit extends HydratedCubit<ChessState> {
  ChessCubit() : super(ChessState());

  @override
  String get id => 'chess_cubit';
  
  void update(Coords fromHere, Coords toHere) {
    // IMPORTANT: deep copy so hydration + rebuilds are safe
    final newBoard = state.board.map((col) => List<String>.from(col)).toList();

    newBoard[toHere.c][toHere.r] = newBoard[fromHere.c][fromHere.r];
    newBoard[fromHere.c][fromHere.r] = " ";

    emit(state.copyWith(board: newBoard, turnCount: state.turnCount + 1));
  }

  @override
ChessState? fromJson(Map<String, dynamic> json) {
  print("LOAD json=$json");

  try {
    final boardData = json['board'];
    final turnCountData = json['turnCount'];

    if (boardData is! List) return null;

    final board = <List<String>>[];
    for (final col in boardData) {
      if (col is! List) return null;
      final colList = <String>[];
      for (final item in col) {
        colList.add(item.toString());
      }
      board.add(colList);
    }

    if (board.length != 8) return null;
    for (final col in board) {
      if (col.length != 8) return null;
    }

    final turnCount = (turnCountData is int)
        ? turnCountData
        : int.tryParse('$turnCountData') ?? 0;

    return ChessState(board: board, turnCount: turnCount);
  } catch (e) {
    print("LOAD ERROR: $e");
    return null;
  }
}


  @override
Map<String, dynamic>? toJson(ChessState state) {
  print("SAVE turnCount=${state.turnCount}");
  return {
    'board': state.board,
    'turnCount': state.turnCount,
  };
}

}
