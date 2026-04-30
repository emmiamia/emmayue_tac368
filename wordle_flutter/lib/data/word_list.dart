import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

class WordList {
  WordList();

  static const int puzzleMinLength = 4;
  static const int puzzleMaxLength = 7;

  final Map<int, Set<String>> _byLength = {};
  bool _loaded = false;

  Set<int> get availableLengths {
    return _byLength.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key)
        .toSet();
  }

  Set<int> get puzzleEligibleLengths {
    return availableLengths
        .where((l) => l >= puzzleMinLength && l <= puzzleMaxLength)
        .toSet();
  }

  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    _byLength.clear();
    await _ingestAsset('assets/words/words.txt');
    await _ingestAsset('assets/words/words_varlen.txt');
    _loaded = true;
  }

  Future<void> _ingestAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final lines = raw.split(RegExp(r'\r?\n'));
    for (final line in lines) {
      final w = line.trim().toUpperCase();
      if (w.isEmpty) continue;
      if (!RegExp(r'^[A-Z]+$').hasMatch(w)) continue;
      _byLength.putIfAbsent(w.length, () => <String>{}).add(w);
    }
  }

  bool isValidWord(String word) {
    final u = word.toUpperCase();
    if (!RegExp(r'^[A-Z]+$').hasMatch(u)) return false;
    return _byLength[u.length]?.contains(u) ?? false;
  }

  /// Random word for a given length, or `null` if the bank has none.
  String? randomWordForLength(int length) {
    final list = _byLength[length]?.toList();
    if (list == null || list.isEmpty) return null;
    return list[Random().nextInt(list.length)];
  }

  /// Random length in [puzzleMinLength]–[puzzleMaxLength] with words in the bank.
  /// If none match (e.g. assets missing), falls back to any loaded length.
  int? randomPuzzleLength() {
    final lens = puzzleEligibleLengths.toList();
    if (lens.isEmpty) {
      final any = availableLengths.toList();
      if (any.isEmpty) return null;
      return any[Random().nextInt(any.length)];
    }
    return lens[Random().nextInt(lens.length)];
  }

  /// Random pick from any loaded length (offline / emergency fallback).
  String randomFallbackWord() {
    final len = randomPuzzleLength();
    if (len == null) return 'CRANE';
    return randomWordForLength(len) ?? 'CRANE';
  }
}
