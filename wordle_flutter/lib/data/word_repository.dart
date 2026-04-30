import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'word_list.dart';

/// Picks a random word length supported by the bank, then a random word from the
/// local bank immediately. In parallel, it fetches Datamuse candidates (same
/// length pattern) intersected with bundled lists and caches them for later.
class WordRepository {
  WordRepository({
    required WordList wordList,
    http.Client? client,
  })  : _wordList = wordList,
        _client = client ?? http.Client();

  final WordList _wordList;
  final http.Client _client;
  final Map<int, List<String>> _cachedApiWords = {};
  final Set<int> _prefetchInFlight = {};
  final Random _random = Random();

  Future<String> fetchSecretWord() async {
    await _wordList.load();
    final wordLength = _wordList.randomPuzzleLength();
    if (wordLength == null) {
      return 'CRANE';
    }

    final cached = _takeCachedWord(wordLength);
    final local = _wordList.randomWordForLength(wordLength) ??
        _wordList.randomFallbackWord();

    // Keep API usage additive only; never block gameplay on network.
    unawaited(_prefetchWordsForLength(wordLength));
    final anotherLength = _wordList.randomPuzzleLength();
    if (anotherLength != null && anotherLength != wordLength) {
      unawaited(_prefetchWordsForLength(anotherLength));
    }

    return cached ?? local;
  }

  String? _takeCachedWord(int length) {
    final list = _cachedApiWords[length];
    if (list == null || list.isEmpty) return null;
    final idx = _random.nextInt(list.length);
    final pick = list[idx];
    list.removeAt(idx);
    return pick;
  }

  Future<void> _prefetchWordsForLength(int wordLength) async {
    if (_prefetchInFlight.contains(wordLength)) return;
    _prefetchInFlight.add(wordLength);
    try {
      final fetched = await _fetchFromApi(wordLength);
      if (fetched.isEmpty) return;

      final merged = <String>{
        ...?_cachedApiWords[wordLength],
        ...fetched,
      }.toList()
        ..sort();
      _cachedApiWords[wordLength] = merged;
    } finally {
      _prefetchInFlight.remove(wordLength);
    }
  }

  Future<List<String>> _fetchFromApi(int wordLength) async {
    try {
      final pattern = List<String>.filled(wordLength, '?').join();
      final uri = Uri.parse(
        'https://api.datamuse.com/words?sp=$pattern&max=1000',
      );
      final res = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return const [];

      final data = json.decode(res.body) as List<dynamic>;
      final candidates = <String>[];
      for (final item in data) {
        if (item is! Map<String, dynamic>) continue;
        final raw = item['word'] as String?;
        if (raw == null) continue;
        final w = raw.toUpperCase();
        if (w.length == wordLength &&
            RegExp(r'^[A-Z]+$').hasMatch(w) &&
            _wordList.isValidWord(w)) {
          candidates.add(w);
        }
      }
      return candidates;
    } catch (_) {
      // Network / parse errors are intentionally ignored.
      return const [];
    }
  }
}
