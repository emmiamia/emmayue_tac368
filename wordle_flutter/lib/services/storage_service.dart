import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists streaks, guess distribution, and recent guess history (JSON).
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  static const _kDistribution = 'wordle_guess_distribution';
  static const _kGamesPlayed = 'wordle_games_played';
  static const _kGamesWon = 'wordle_games_won';
  static const _kCurrentStreak = 'wordle_current_streak';
  static const _kBestStreak = 'wordle_best_streak';
  static const _kLastWin = 'wordle_last_win_ymd';
  static const _kLastPlayed = 'wordle_last_played_ymd';
  static const _kGuessHistory = 'wordle_guess_history';
  static const _maxHistoryEntries = 50;

  static final _ymd = DateFormat('yyyy-MM-dd');

  Future<List<int>> get guessDistribution async {
    final raw = _prefs.getString(_kDistribution);
    if (raw == null) return List.filled(6, 0);
    final list = (json.decode(raw) as List<dynamic>).cast<int>();
    if (list.length != 6) return List.filled(6, 0);
    return list;
  }

  Future<int> get gamesPlayed async => _prefs.getInt(_kGamesPlayed) ?? 0;

  Future<int> get gamesWon async => _prefs.getInt(_kGamesWon) ?? 0;

  Future<int> get currentStreak async => _prefs.getInt(_kCurrentStreak) ?? 0;

  Future<int> get bestStreak async => _prefs.getInt(_kBestStreak) ?? 0;

  Future<List<GuessHistoryEntry>> get guessHistory async {
    final raw = _prefs.getString(_kGuessHistory);
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) => GuessHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _today() => _ymd.format(DateTime.now());

  Future<void> appendGuessHistory({
    required bool won,
    required int attempts,
    required List<String> guesses,
  }) async {
    final entry = GuessHistoryEntry(
      date: _today(),
      won: won,
      attempts: attempts,
      guesses: List<String>.from(guesses),
    );
    final list = await guessHistory;
    list.insert(0, entry);
    while (list.length > _maxHistoryEntries) {
      list.removeLast();
    }
    final encoded = json.encode(list.map((e) => e.toJson()).toList());
    await _prefs.setString(_kGuessHistory, encoded);
  }

  Future<void> recordWin({required int guessCount}) async {
    final today = _today();
    final idx = guessCount.clamp(1, 6) - 1;

    final dist = await guessDistribution;
    dist[idx] += 1;

    final played = await gamesPlayed;
    final won = await gamesWon;
    var streak = await currentStreak;
    streak += 1;

    var best = await bestStreak;
    if (streak > best) best = streak;

    await _prefs.setString(_kDistribution, json.encode(dist));
    await _prefs.setInt(_kGamesPlayed, played + 1);
    await _prefs.setInt(_kGamesWon, won + 1);
    await _prefs.setInt(_kCurrentStreak, streak);
    await _prefs.setInt(_kBestStreak, best);
    await _prefs.setString(_kLastWin, today);
    await _prefs.setString(_kLastPlayed, today);
  }

  Future<void> recordLoss() async {
    final today = _today();
    final played = await gamesPlayed;
    await _prefs.setInt(_kGamesPlayed, played + 1);
    await _prefs.setInt(_kCurrentStreak, 0);
    await _prefs.setString(_kLastPlayed, today);
  }
}

class GuessHistoryEntry {
  GuessHistoryEntry({
    required this.date,
    required this.won,
    required this.attempts,
    required this.guesses,
  });

  final String date;
  final bool won;
  final int attempts;
  final List<String> guesses;

  Map<String, dynamic> toJson() => {
        'date': date,
        'won': won,
        'attempts': attempts,
        'guesses': guesses,
      };

  static GuessHistoryEntry fromJson(Map<String, dynamic> j) {
    return GuessHistoryEntry(
      date: j['date'] as String? ?? '',
      won: j['won'] as bool? ?? false,
      attempts: (j['attempts'] as num?)?.toInt() ?? 0,
      guesses: (j['guesses'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}
