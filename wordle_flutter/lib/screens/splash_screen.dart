import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

import '../data/word_list.dart';
import '../data/word_repository.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import 'game_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.storageService,
    required this.wordList,
    required this.wordRepository,
    required this.soundService,
  });

  final StorageService storageService;
  final WordList wordList;
  final WordRepository wordRepository;
  final SoundService soundService;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          storageService: widget.storageService,
          wordList: widget.wordList,
          wordRepository: widget.wordRepository,
          soundService: widget.soundService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.appTitle,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    letterSpacing: 8,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.splashSubtitle,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
