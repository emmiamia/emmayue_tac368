import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'word_list.dart';

/// Picks a random word length supported by the bank, then a random word from the
/// Datamuse API for that length (pattern of `?`), intersected with the bundled
/// lists. Falls back to a random local word for the chosen length.
class WordRepository {
  WordRepository({
    required WordList wordList,
    http.Client? client,
  })  : _wordList = wordList,
        _client = client ?? http.Client();

  final WordList _wordList;
  final http.Client _client;

  Future<String> fetchSecretWord() async {
    await _wordList.load();
    final wordLength = _wordList.randomPuzzleLength();
    if (wordLength == null) {
      return 'CRANE';
    }

    try {
      final pattern = List<String>.filled(wordLength, '?').join();
      final uri = Uri.parse(
        'https://api.datamuse.com/words?sp=$pattern&max=1000',
      );
      final res = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
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
        candidates.sort();
        if (candidates.isNotEmpty) {
          final idx = Random().nextInt(candidates.length);
          return candidates[idx];
        }
      }
    } catch (_) {
      // Network / parse errors — fall through to local fallback.
    }

    return _wordList.randomWordForLength(wordLength) ??
        _wordList.randomFallbackWord();
  }
}
