import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/word_list.dart';
import 'l10n/app_localizations.dart';
import 'data/word_repository.dart';
import 'locale/locale_cubit.dart';
import 'screens/splash_screen.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';
import 'theme/theme_cubit.dart';

class WordleApp extends StatelessWidget {
  const WordleApp({
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

  static const _green = Color(0xFF6AAA64);
  static const _yellow = Color(0xFFC9B458);
  static const _gray = Color(0xFF787C7E);
  static const _darkBg = Color(0xFF121213);
  static const _lightBg = Color(0xFFFFFFFF);

  static ThemeData _darkTheme() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: _darkBg,
      colorScheme: const ColorScheme.dark(
        primary: _green,
        secondary: _yellow,
        surface: _darkBg,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
    return base.copyWith(
      extensions: const [
        WordleColors(
          correct: _green,
          present: _yellow,
          absent: _gray,
          tileBorder: Color(0xFF3A3A3C),
          tileEmptyFill: _darkBg,
        ),
      ],
    );
  }

  static ThemeData _lightTheme() {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: _lightBg,
      colorScheme: ColorScheme.light(
        primary: _green,
        secondary: _yellow,
        surface: _lightBg,
        onSurface: Colors.black87,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightBg,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
    return base.copyWith(
      extensions: const [
        WordleColors(
          correct: _green,
          present: _yellow,
          absent: _gray,
          tileBorder: Color(0xFF878A8C),
          tileEmptyFill: _lightBg,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
            return MaterialApp(
              onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
              debugShowCheckedModeBanner: false,
              theme: _lightTheme(),
              darkTheme: _darkTheme(),
              themeMode: themeMode,
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: SplashScreen(
                storageService: storageService,
                wordList: wordList,
                wordRepository: wordRepository,
                soundService: soundService,
              ),
            );
          },
        );
      },
    );
  }
}

class WordleColors extends ThemeExtension<WordleColors> {
  const WordleColors({
    required this.correct,
    required this.present,
    required this.absent,
    required this.tileBorder,
    required this.tileEmptyFill,
  });

  final Color correct;
  final Color present;
  final Color absent;
  final Color tileBorder;
  final Color tileEmptyFill;

  @override
  WordleColors copyWith({
    Color? correct,
    Color? present,
    Color? absent,
    Color? tileBorder,
    Color? tileEmptyFill,
  }) {
    return WordleColors(
      correct: correct ?? this.correct,
      present: present ?? this.present,
      absent: absent ?? this.absent,
      tileBorder: tileBorder ?? this.tileBorder,
      tileEmptyFill: tileEmptyFill ?? this.tileEmptyFill,
    );
  }

  @override
  ThemeExtension<WordleColors> lerp(
    ThemeExtension<WordleColors>? other,
    double t,
  ) {
    if (other is! WordleColors) return this;
    return WordleColors(
      correct: Color.lerp(correct, other.correct, t)!,
      present: Color.lerp(present, other.present, t)!,
      absent: Color.lerp(absent, other.absent, t)!,
      tileBorder: Color.lerp(tileBorder, other.tileBorder, t)!,
      tileEmptyFill: Color.lerp(tileEmptyFill, other.tileEmptyFill, t)!,
    );
  }
}

extension WordleColorsX on BuildContext {
  WordleColors get wordle => Theme.of(this).extension<WordleColors>()!;
}
