import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/word_list.dart';
import '../data/word_repository.dart';
import '../models/game_state.dart' as domain;
import '../models/letter_state.dart';
import '../models/tile.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc({
    required WordRepository wordRepository,
    required WordList wordList,
    required StorageService storageService,
    required SoundService soundService,
  })  : _wordRepository = wordRepository,
        _wordList = wordList,
        _storage = storageService,
        _sounds = soundService,
        super(const GameLoading()) {
    on<GameInitialize>(_onInitialize);
    on<LetterEntered>(_onLetter);
    on<BackspacePressed>(_onBackspace);
    on<WordSubmitted>(_onSubmit);
    on<GameReset>(_onReset);
    on<GameDismissMessage>(_onDismiss);
    on<GameRevealForfeit>(_onRevealForfeit);
  }

  final WordRepository _wordRepository;
  final WordList _wordList;
  final StorageService _storage;
  final SoundService _sounds;

  String _secret = '';

  int get _wordLength => _secret.length;

  Future<void> _onInitialize(GameInitialize event, Emitter<GameState> emit) async {
    emit(const GameLoading());
    await _wordList.load();
    _secret = await _wordRepository.fetchSecretWord();
    _logSecretForDemo();
    final streak = await _storage.currentStreak;
    emit(GamePlaying(
      gameplay: _freshGameplay(streak: streak),
    ));
  }

  domain.GameplayModel _freshGameplay({required int streak}) {
    return domain.GameplayModel(
      board: _emptyBoard(),
      currentRow: 0,
      currentColumn: 0,
      secretWord: _secret,
      keyboardStates: {},
      streak: streak,
    );
  }

  List<List<Tile>> _emptyBoard() {
    final n = _wordLength;
    return List.generate(
      6,
      (_) => List.generate(n, (_) => const Tile()),
    );
  }

  Future<void> _onReset(GameReset event, Emitter<GameState> emit) async {
    emit(const GameLoading());
    await _wordList.load();
    _secret = await _wordRepository.fetchSecretWord();
    _logSecretForDemo();
    final streak = await _storage.currentStreak;
    emit(GamePlaying(gameplay: _freshGameplay(streak: streak)));
  }

  void _logSecretForDemo() {
    // Demo helper: prints the answer only in terminal output.
    // ignore: avoid_print
    print('[DEMO] Secret answer: $_secret');
  }

  Future<void> _onRevealForfeit(
    GameRevealForfeit event,
    Emitter<GameState> emit,
  ) async {
    final s = state;
    if (s is! GamePlaying) return;
    var g = s.gameplay;
    if (g.hasWon || g.hasLost) return;

    final cols = g.secretWord.length;
    final prevRow = g.currentRow;
    final guesses = <String>[];
    for (var r = 0; r < prevRow; r++) {
      guesses.add(g.board[r].map((t) => t.letter).join());
    }
    guesses.add(_secret);

    final revealed = List<Tile>.generate(
      cols,
      (i) => Tile(letter: _secret[i], state: LetterState.correct),
    );
    final board = [...g.board];
    board[prevRow] = revealed;

    var keys = Map<String, LetterState>.from(g.keyboardStates);
    final eval = _evaluateGuess(_secret, _secret);
    for (var i = 0; i < cols; i++) {
      final letter = _secret[i];
      final prev = keys[letter] ?? LetterState.empty;
      keys[letter] = mergeKeyState(prev, eval[i]);
    }

    g = g.copyWith(
      board: board,
      keyboardStates: keys,
      hasLost: true,
      currentColumn: cols,
    );

    await _storage.appendGuessHistory(
      won: false,
      attempts: guesses.length,
      guesses: guesses,
    );
    await _storage.recordLoss();
    await _sounds.playWrong();
    final streak = await _storage.currentStreak;
    emit(GameLost(gameplay: g.copyWith(streak: streak)));
  }

  void _onDismiss(GameDismissMessage event, Emitter<GameState> emit) {
    final s = state;
    if (s is GamePlaying) {
      emit(s.copyWith(clearSnackbar: true));
    }
  }

  void _onLetter(LetterEntered event, Emitter<GameState> emit) {
    final s = state;
    if (s is! GamePlaying) return;
    final g = s.gameplay;
    final cols = g.secretWord.length;
    if (g.hasWon || g.hasLost) return;
    if (g.currentRow >= 6) return;
    final ch = event.letter.toUpperCase();
    if (ch.length != 1 || ch.codeUnitAt(0) < 65 || ch.codeUnitAt(0) > 90) return;
    if (g.currentColumn >= cols) return;

    final row = List<Tile>.from(g.board[g.currentRow]);
    row[g.currentColumn] = Tile(letter: ch, state: LetterState.filled);
    final board = [...g.board];
    board[g.currentRow] = row;

    emit(s.copyWith(
      gameplay: g.copyWith(
        board: board,
        currentColumn: g.currentColumn + 1,
      ),
      clearSnackbar: true,
    ));
  }

  void _onBackspace(BackspacePressed event, Emitter<GameState> emit) {
    final s = state;
    if (s is! GamePlaying) return;
    final g = s.gameplay;
    if (g.hasWon || g.hasLost) return;
    if (g.currentColumn <= 0) return;

    final row = List<Tile>.from(g.board[g.currentRow]);
    row[g.currentColumn - 1] = const Tile();
    final board = [...g.board];
    board[g.currentRow] = row;

    emit(s.copyWith(
      gameplay: g.copyWith(
        board: board,
        currentColumn: g.currentColumn - 1,
      ),
      clearSnackbar: true,
    ));
  }

  List<String> _guessesFromBoard(domain.GameplayModel g, int rowCount) {
    return List.generate(
      rowCount,
      (r) => g.board[r].map((t) => t.letter).join(),
    );
  }

  Future<void> _onSubmit(WordSubmitted event, Emitter<GameState> emit) async {
    final s = state;
    if (s is! GamePlaying) return;
    var g = s.gameplay;
    final cols = g.secretWord.length;
    if (g.hasWon || g.hasLost) return;
    if (g.currentColumn < cols) {
      emit(s.copyWith(snackbarKey: 'not_enough'));
      return;
    }

    final guess = g.board[g.currentRow].map((t) => t.letter).join();
    if (!_wordList.isValidWord(guess)) {
      await _sounds.playWrong();
      emit(s.copyWith(
        snackbarKey: 'not_in_list',
        shakeVersion: s.shakeVersion + 1,
        shakeRow: g.currentRow,
      ));
      return;
    }

    await _sounds.playCorrect();
    final eval = _evaluateGuess(guess, _secret);
    final row = List<Tile>.generate(
      cols,
      (i) => Tile(letter: guess[i], state: eval[i]),
    );
    final board = [...g.board];
    board[g.currentRow] = row;

    var keys = Map<String, LetterState>.from(g.keyboardStates);
    for (var i = 0; i < cols; i++) {
      final letter = guess[i];
      final prev = keys[letter] ?? LetterState.empty;
      keys[letter] = mergeKeyState(prev, eval[i]);
    }

    final won = guess == _secret;
    final nextRow = g.currentRow + 1;
    final lost = !won && nextRow >= 6;

    g = g.copyWith(
      board: board,
      keyboardStates: keys,
      currentRow: won || lost ? g.currentRow : nextRow,
      currentColumn: won || lost ? g.currentColumn : 0,
      hasWon: won,
      hasLost: lost,
    );

    if (won) {
      final guesses = _guessesFromBoard(g, g.currentRow + 1);
      await _storage.appendGuessHistory(
        won: true,
        attempts: nextRow,
        guesses: guesses,
      );
      await _storage.recordWin(guessCount: nextRow);
      await _sounds.playWin();
      final streak = await _storage.currentStreak;
      emit(GameWon(
        gameplay: g.copyWith(streak: streak),
        guessCount: nextRow,
      ));
      return;
    }

    if (lost) {
      final guesses = _guessesFromBoard(g, 6);
      await _storage.appendGuessHistory(
        won: false,
        attempts: 6,
        guesses: guesses,
      );
      await _storage.recordLoss();
      final streak = await _storage.currentStreak;
      emit(GameLost(gameplay: g.copyWith(streak: streak)));
      return;
    }

    emit(s.copyWith(gameplay: g, shakeRow: -1));
  }

  List<LetterState> _evaluateGuess(String guess, String answer) {
    final n = answer.length;
    final g = guess.toUpperCase().split('');
    final a = answer.toUpperCase().split('');
    final result = List<LetterState>.filled(n, LetterState.absent);
    final remaining = <String, int>{};
    for (var i = 0; i < n; i++) {
      remaining[a[i]] = (remaining[a[i]] ?? 0) + 1;
    }
    for (var i = 0; i < n; i++) {
      if (g[i] == a[i]) {
        result[i] = LetterState.correct;
        remaining[g[i]] = remaining[g[i]]! - 1;
      }
    }
    for (var i = 0; i < n; i++) {
      if (result[i] == LetterState.correct) continue;
      final c = g[i];
      if ((remaining[c] ?? 0) > 0) {
        result[i] = LetterState.present;
        remaining[c] = remaining[c]! - 1;
      }
    }
    return result;
  }
}
