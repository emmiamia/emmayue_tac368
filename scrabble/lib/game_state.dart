// Game logic and line-based socket protocol; host owns the bag and sends INIT/PLAY/REFILL as needed.

import "dart:math";
import "package:flutter_bloc/flutter_bloc.dart";
import "yak_state.dart";

class GameState {
  final bool iAmHost;
  final bool myTurn;
  final List<String> board;
  final List<String> myRack;
  final int oppRackCount;
  final String status;
  final bool gameOver;
  final int? selectedRackIndex;
  final List<int> placedThisTurn;
  final List<String> bag;
  final List<String> pendingInitRack;
  final bool initSent;
  final bool awaitingRefill;
  final int myScore;
  final int oppScore;

  GameState(
    this.iAmHost,
    this.myTurn,
    this.board,
    this.myRack,
    this.oppRackCount,
    this.status,
    this.gameOver,
    this.selectedRackIndex,
    this.placedThisTurn,
    this.bag,
    this.pendingInitRack,
    this.initSent,
    this.awaitingRefill,
    this.myScore,
    this.oppScore,
  );

  GameState copyWith({
    bool? iAmHost,
    bool? myTurn,
    List<String>? board,
    List<String>? myRack,
    int? oppRackCount,
    String? status,
    bool? gameOver,
    int? selectedRackIndex,
    bool clearSelectedRackIndex = false,
    List<int>? placedThisTurn,
    List<String>? bag,
    List<String>? pendingInitRack,
    bool? initSent,
    bool? awaitingRefill,
    int? myScore,
    int? oppScore,
  }) {
    return GameState(
      iAmHost ?? this.iAmHost,
      myTurn ?? this.myTurn,
      board ?? List<String>.from(this.board),
      myRack ?? List<String>.from(this.myRack),
      oppRackCount ?? this.oppRackCount,
      status ?? this.status,
      gameOver ?? this.gameOver,
      clearSelectedRackIndex ? null : (selectedRackIndex ?? this.selectedRackIndex),
      placedThisTurn ?? List<int>.from(this.placedThisTurn),
      bag ?? List<String>.from(this.bag),
      pendingInitRack ?? List<String>.from(this.pendingInitRack),
      initSent ?? this.initSent,
      awaitingRefill ?? this.awaitingRefill,
      myScore ?? this.myScore,
      oppScore ?? this.oppScore,
    );
  }
}

class GameCubit extends Cubit<GameState> {
  static const int boardSide = 15;
  static const int boardSize = boardSide * boardSide;
  static const String emptyBoard = ".";

  final Random rng = Random();

  GameCubit(bool iAmHost)
      : super(_initialState(iAmHost));

  static GameState _initialState(bool iAmHost) {
    if (iAmHost) {
      final bag = _makeBag();
      _shuffle(bag);
      final hostRack = _drawFromBagStatic(bag, 7);
      final clientRack = _drawFromBagStatic(bag, 7);

      return GameState(
        true,
        true,
        List<String>.filled(boardSize, emptyBoard),
        hostRack,
        7,
        "Connected. Your turn.",
        false,
        null,
        [],
        bag,
        clientRack,
        false,
        false,
        0,
        0,
      );
    } else {
      return GameState(
        false,
        false,
        List<String>.filled(boardSize, emptyBoard),
        List<String>.filled(7, ""),
        7,
        "Connected. Waiting for host setup...",
        false,
        null,
        [],
        [],
        [],
        true,
        false,
        0,
        0,
      );
    }
  }

  static List<String> _makeBag() {
    final letters = <String>[];
    void addMany(String ch, int n) {
      for (int i = 0; i < n; i++) {
        letters.add(ch);
      }
    }

    addMany("A", 9);
    addMany("B", 2);
    addMany("C", 2);
    addMany("D", 4);
    addMany("E", 12);
    addMany("F", 2);
    addMany("G", 3);
    addMany("H", 2);
    addMany("I", 9);
    addMany("J", 1);
    addMany("K", 1);
    addMany("L", 4);
    addMany("M", 2);
    addMany("N", 6);
    addMany("O", 8);
    addMany("P", 2);
    addMany("Q", 1);
    addMany("R", 6);
    addMany("S", 4);
    addMany("T", 6);
    addMany("U", 4);
    addMany("V", 2);
    addMany("W", 2);
    addMany("X", 1);
    addMany("Y", 2);
    addMany("Z", 1);

    return letters;
  }

  static void _shuffle(List<String> list) {
    final rng = Random();
    for (int i = list.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }

  static List<String> _drawFromBagStatic(List<String> bag, int n) {
    final drawn = <String>[];
    for (int i = 0; i < n && bag.isNotEmpty; i++) {
      drawn.add(bag.removeLast());
    }
    while (drawn.length < n) {
      drawn.add("");
    }
    return drawn;
  }

  bool isEmptyRackSlot(int i) {
    if (i < 0 || i >= state.myRack.length) return true;
    return state.myRack[i].isEmpty;
  }

  bool canSelectRack(int i) {
    if (state.gameOver) return false;
    if (!state.myTurn) return false;
    if (state.awaitingRefill) return false;
    if (i < 0 || i >= state.myRack.length) return false;
    if (state.myRack[i].isEmpty) return false;
    return true;
  }

  bool canPlaceAt(int boardIndex) {
    if (state.gameOver) return false;
    if (!state.myTurn) return false;
    if (state.awaitingRefill) return false;
    if (boardIndex < 0 || boardIndex >= boardSize) return false;
    if (state.board[boardIndex] != emptyBoard) return false;
    if (state.selectedRackIndex == null) return false;
    final ri = state.selectedRackIndex!;
    if (ri < 0 || ri >= state.myRack.length) return false;
    if (state.myRack[ri].isEmpty) return false;
    return true;
  }

  void selectRack(int i) {
    if (!canSelectRack(i)) return;
    emit(
      state.copyWith(
        selectedRackIndex: i,
        status: "Selected ${state.myRack[i]}",
      ),
    );
  }

  void placeSelectedAt(int boardIndex) {
    if (!canPlaceAt(boardIndex)) return;

    final ri = state.selectedRackIndex!;
    final letter = state.myRack[ri];

    final newBoard = List<String>.from(state.board);
    final newRack = List<String>.from(state.myRack);
    final newPlaced = List<int>.from(state.placedThisTurn);

    newBoard[boardIndex] = letter;
    newRack[ri] = "";
    newPlaced.add(boardIndex);

    emit(
      state.copyWith(
        board: newBoard,
        myRack: newRack,
        placedThisTurn: newPlaced,
        clearSelectedRackIndex: true,
        status: "Placed $letter",
      ),
    );
  }

  void onConnected(YakCubit yc) {
    if (state.iAmHost && !state.initSent) {
      yc.say("INIT ${state.pendingInitRack.join()}");
      emit(
        state.copyWith(
          pendingInitRack: [],
          initSent: true,
          status: "Connected. Your turn.",
        ),
      );
    }
  }

  void setInitialRack(String letters) {
    final rack = letters.split("");
    while (rack.length < 7) {
      rack.add("");
    }
    emit(
      state.copyWith(
        myRack: rack.take(7).toList(),
        oppRackCount: 7,
        status: "Connected. Opponent's turn.",
      ),
    );
  }


  String _placementsPayload(List<int> positions, List<String> board) {
    final parts = <String>[];
    for (final p in positions) {
      parts.add("$p:${board[p]}");
    }
    return parts.join(",");
  }

  List<MapEntry<int, String>> _parsePlacements(String s) {
    final ans = <MapEntry<int, String>>[];
    final trimmed = s.trim();
    if (trimmed.isEmpty) return ans;

    final items = trimmed.split(",");
    for (final item in items) {
      final pair = item.split(":");
      if (pair.length != 2) continue;
      final pos = int.tryParse(pair[0].trim());
      final letter = pair[1].trim();
      if (pos == null) continue;
      if (pos < 0 || pos >= boardSize) continue;
      if (letter.isEmpty) continue;
      ans.add(MapEntry(pos, letter));
    }
    return ans;
  }

  List<String> _drawRefillLetters(List<String> bag, int n) {
    final drawn = <String>[];
    for (int i = 0; i < n && bag.isNotEmpty; i++) {
      drawn.add(bag.removeLast());
    }
    return drawn;
  }

  List<String> _fillRackBlanks(List<String> rack, List<String> letters) {
    final newRack = List<String>.from(rack);
    int li = 0;
    for (int i = 0; i < newRack.length && li < letters.length; i++) {
      if (newRack[i].isEmpty) {
        newRack[i] = letters[li];
        li++;
      }
    }
    return newRack;
  }

  void endTurnLocal(YakCubit yc) {
    if (state.gameOver) return;
    if (!state.myTurn) return;
    if (state.awaitingRefill) return;
    if (state.placedThisTurn.isEmpty) return;

    final placedCount = state.placedThisTurn.length;
    final payload = _placementsPayload(state.placedThisTurn, state.board);

    if (state.iAmHost) {
      final newBag = List<String>.from(state.bag);
      final refill = _drawRefillLetters(newBag, placedCount);
      final newRack = _fillRackBlanks(state.myRack, refill);
      final refillCount = refill.length;

      yc.say("PLAY $payload|$refillCount");

      emit(
        state.copyWith(
          bag: newBag,
          myRack: newRack,
          myTurn: false,
          status: "Opponent's turn.",
          placedThisTurn: [],
          clearSelectedRackIndex: true,
          myScore: state.myScore + placedCount,
        ),
      );
    } else {
      yc.say("PLAY $payload");

      emit(
        state.copyWith(
          myTurn: false,
          awaitingRefill: true,
          status: "Turn sent. Waiting for refill from host...",
          placedThisTurn: [],
          clearSelectedRackIndex: true,
          myScore: state.myScore + placedCount,
        ),
      );
    }
  }

  void applyRemotePlayAsClient(String placementText, int refillCount) {
    if (state.gameOver) return;

    final placements = _parsePlacements(placementText);
    final newBoard = List<String>.from(state.board);

    for (final entry in placements) {
      if (newBoard[entry.key] == emptyBoard) {
        newBoard[entry.key] = entry.value;
      }
    }

    final used = placements.length;
    final newOppCount = (state.oppRackCount - used + refillCount).clamp(0, 7);

    emit(
      state.copyWith(
        board: newBoard,
        oppRackCount: newOppCount,
        myTurn: true,
        status: "Your turn.",
        oppScore: state.oppScore + used,
      ),
    );
  }

  void applyRemotePlayAsHost(String placementText, YakCubit yc) {
    if (state.gameOver) return;

    final placements = _parsePlacements(placementText);
    final newBoard = List<String>.from(state.board);

    for (final entry in placements) {
      if (newBoard[entry.key] == emptyBoard) {
        newBoard[entry.key] = entry.value;
      }
    }

    final used = placements.length;
    final newBag = List<String>.from(state.bag);
    final refillLetters = _drawRefillLetters(newBag, used);
    final refillCount = refillLetters.length;

    yc.say("REFILL ${refillLetters.join()}");

    final newOppCount = (state.oppRackCount - used + refillCount).clamp(0, 7);

    emit(
      state.copyWith(
        board: newBoard,
        bag: newBag,
        oppRackCount: newOppCount,
        myTurn: true,
        status: "Your turn.",
        oppScore: state.oppScore + used,
      ),
    );
  }

  void receiveRefill(String letters) {
    final chars = letters.split("");
    final newRack = _fillRackBlanks(state.myRack, chars);

    emit(
      state.copyWith(
        myRack: newRack,
        awaitingRefill: false,
        status: "Opponent's turn.",
      ),
    );
  }

  void passLocal(YakCubit yc) {
    if (state.gameOver) return;
    if (!state.myTurn) return;
    if (state.awaitingRefill) return;

    yc.say("PASS");
    emit(
      state.copyWith(
        myTurn: false,
        clearSelectedRackIndex: true,
        status: "You passed. Opponent's turn.",
      ),
    );
  }

  void passRemote() {
    if (state.gameOver) return;
    emit(
      state.copyWith(
        myTurn: true,
        status: "Opponent passed. Your turn.",
      ),
    );
  }

  void resignLocal(YakCubit yc) {
    if (state.gameOver) return;
    yc.say("RESIGN");
    emit(
      state.copyWith(
        gameOver: true,
        myTurn: false,
        status: "You resigned.",
      ),
    );
  }

  void resignRemote() {
    if (state.gameOver) return;
    emit(
      state.copyWith(
        gameOver: true,
        myTurn: false,
        status: "Opponent resigned. You win.",
      ),
    );
  }

  void handle(String msg, YakCubit yc) {
    final text = msg.trim();
    if (text.isEmpty) return;

    if (text.startsWith("INIT ")) {
      setInitialRack(text.substring(5).trim());
      return;
    }

    if (text.startsWith("PLAY ")) {
      final body = text.substring(5).trim();

      if (state.iAmHost) {
        applyRemotePlayAsHost(body, yc);
      } else {
        final parts = body.split("|");
        final placementText = parts[0].trim();
        int refillCount = 0;
        if (parts.length > 1) {
          refillCount = int.tryParse(parts[1].trim()) ?? 0;
        }
        applyRemotePlayAsClient(placementText, refillCount);
      }
      return;
    }

    if (text.startsWith("REFILL ")) {
      receiveRefill(text.substring(7).trim());
      return;
    }

    if (text == "PASS") {
      passRemote();
      return;
    }

    if (text == "RESIGN") {
      resignRemote();
      return;
    }
  }
}