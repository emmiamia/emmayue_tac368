import "package:flutter_bloc/flutter_bloc.dart";

class GameState {
  final bool iStart;
  final bool myTurn;
  final List<String> board;
  final String status;
  final bool gameOver;
  final String myMark;
  final String oppMark;

  GameState(
    this.iStart,
    this.myTurn,
    this.board,
    this.status,
    this.gameOver,
    this.myMark,
    this.oppMark,
  );

  GameState copyWith({
    bool? iStart,
    bool? myTurn,
    List<String>? board,
    String? status,
    bool? gameOver,
    String? myMark,
    String? oppMark,
  }) {
    return GameState(
      iStart ?? this.iStart,
      myTurn ?? this.myTurn,
      board ?? List<String>.from(this.board),
      status ?? this.status,
      gameOver ?? this.gameOver,
      myMark ?? this.myMark,
      oppMark ?? this.oppMark,
    );
  }
}

class GameCubit extends Cubit<GameState> {
  static const String d = ".";

  GameCubit(bool iStart)
      : super(
          GameState(
            iStart,
            iStart,
            List<String>.filled(9, d),
            iStart ? "Your turn" : "Opponent's turn",
            false,
            iStart ? "x" : "o",
            iStart ? "o" : "x",
          ),
        );

  bool canPlay(int where) {
    if (state.gameOver) return false;
    if (!state.myTurn) return false;
    if (where < 0 || where > 8) return false;
    if (state.board[where] != d) return false;
    return true;
  }

  bool localPlay(int where) {
    if (!canPlay(where)) return false;

    List<String> nb = List<String>.from(state.board);
    nb[where] = state.myMark;

    String result = winner(nb);
    if (result == state.myMark) {
      emit(
        state.copyWith(
          board: nb,
          myTurn: false,
          status: "You win",
          gameOver: true,
        ),
      );
    } else if (isDraw(nb)) {
      emit(
        state.copyWith(
          board: nb,
          myTurn: false,
          status: "Draw",
          gameOver: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          board: nb,
          myTurn: false,
          status: "Opponent's turn",
        ),
      );
    }
    return true;
  }

  void remotePlay(int where) {
    if (state.gameOver) return;
    if (where < 0 || where > 8) return;
    if (state.board[where] != d) return;

    List<String> nb = List<String>.from(state.board);
    nb[where] = state.oppMark;

    String result = winner(nb);
    if (result == state.oppMark) {
      emit(
        state.copyWith(
          board: nb,
          myTurn: false,
          status: "You lose",
          gameOver: true,
        ),
      );
    } else if (isDraw(nb)) {
      emit(
        state.copyWith(
          board: nb,
          myTurn: false,
          status: "Draw",
          gameOver: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          board: nb,
          myTurn: true,
          status: "Your turn",
        ),
      );
    }
  }

  void resignLocal() {
    if (state.gameOver) return;
    emit(state.copyWith(status: "You resigned", gameOver: true, myTurn: false));
  }

  void resignRemote() {
    if (state.gameOver) return;
    emit(state.copyWith(status: "Opponent resigned. You win", gameOver: true, myTurn: false));
  }

  void passLocal() {
    if (state.gameOver) return;
    emit(state.copyWith(myTurn: false, status: "You passed"));
  }

  void passRemote() {
    if (state.gameOver) return;
    emit(state.copyWith(myTurn: true, status: "Opponent passed. Your turn"));
  }

  void handle(String msg) {
    List<String> parts = msg.trim().split(" ");
    if (parts.isEmpty) return;

    if (parts[0] == "MOVE" && parts.length > 1) {
      int where = int.parse(parts[1]);
      remotePlay(where);
    } else if (parts[0] == "RESIGN") {
      resignRemote();
    } else if (parts[0] == "PASS") {
      passRemote();
    }
  }

  String winner(List<String> b) {
    const lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (final line in lines) {
      String a = b[line[0]];
      if (a != d && a == b[line[1]] && a == b[line[2]]) {
        return a;
      }
    }
    return "";
  }

  bool isDraw(List<String> b) {
    if (winner(b).isNotEmpty) return false;
    return !b.contains(d);
  }
}