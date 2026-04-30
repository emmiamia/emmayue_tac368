import 'package:flutter/material.dart';

/// Minimal localization (English + 中文) — ARB files in the same folder mirror strings for tooling.
abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('zh'),
  ];

  String get appTitle;
  String get statisticsTitle;
  String get splashSubtitle;
  String get messageNotEnoughLetters;
  String get messageNotInWordList;
  String get winDialogTitle;
  String winDialogBody(int count, int streak);
  String get loseDialogTitle;
  String loseDialogBody(String word);
  String get playAgain;
  String get close;
  String get statsPlayed;
  String get statsWinPercent;
  String get statsStreak;
  String get statsBest;
  String get guessDistribution;
  String get recentGames;
  String get historyWin;
  String get historyLoss;
  String historyAttempts(int count);
  String get toggleTheme;
  String get language;
  String get languageEnglish;
  String get languageChinese;
  String get newGame;
  String get revealAnswer;
  String get revealForfeitTitle;
  String get revealForfeitBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'zh';

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'zh':
        return AppLocalizationsZh();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

class AppLocalizationsEn extends AppLocalizations {
  @override
  String get appTitle => 'WORDLE';

  @override
  String get statisticsTitle => 'Statistics';

  @override
  String get splashSubtitle => 'Loading…';

  @override
  String get messageNotEnoughLetters => 'Not enough letters';

  @override
  String get messageNotInWordList => 'Not in word list';

  @override
  String get winDialogTitle => 'Splendid';

  @override
  String winDialogBody(int count, int streak) =>
      'You solved it in $count tries. Current streak: $streak.';

  @override
  String get loseDialogTitle => 'Nice try';

  @override
  String loseDialogBody(String word) => 'The word was $word.';

  @override
  String get playAgain => 'Play again';

  @override
  String get close => 'Close';

  @override
  String get statsPlayed => 'Played';

  @override
  String get statsWinPercent => 'Win %';

  @override
  String get statsStreak => 'Streak';

  @override
  String get statsBest => 'Best';

  @override
  String get guessDistribution => 'Guess distribution';

  @override
  String get recentGames => 'Recent games';

  @override
  String get historyWin => 'Win';

  @override
  String get historyLoss => 'Loss';

  @override
  String historyAttempts(int count) => '$count tries';

  @override
  String get toggleTheme => 'Toggle brightness';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get newGame => 'New game';

  @override
  String get revealAnswer => 'Reveal answer';

  @override
  String get revealForfeitTitle => 'Reveal and forfeit?';

  @override
  String get revealForfeitBody =>
      'The answer will be filled in and this game will count as a loss.';
}

class AppLocalizationsZh extends AppLocalizations {
  @override
  String get appTitle => '猜词';

  @override
  String get statisticsTitle => '统计';

  @override
  String get splashSubtitle => '加载中…';

  @override
  String get messageNotEnoughLetters => '字母不够';

  @override
  String get messageNotInWordList => '不在词表中';

  @override
  String get winDialogTitle => '太棒了';

  @override
  String winDialogBody(int count, int streak) =>
      '你在 $count 次内猜中了！当前连胜：$streak。';

  @override
  String get loseDialogTitle => '再接再厉';

  @override
  String loseDialogBody(String word) => '答案是 $word。';

  @override
  String get playAgain => '再玩一局';

  @override
  String get close => '关闭';

  @override
  String get statsPlayed => '局数';

  @override
  String get statsWinPercent => '胜率';

  @override
  String get statsStreak => '连胜';

  @override
  String get statsBest => '最佳';

  @override
  String get guessDistribution => '猜测次数分布';

  @override
  String get recentGames => '最近对局';

  @override
  String get historyWin => '胜';

  @override
  String get historyLoss => '负';

  @override
  String historyAttempts(int count) => '$count 次';

  @override
  String get toggleTheme => '切换明暗主题';

  @override
  String get language => '语言';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get newGame => '新游戏';

  @override
  String get revealAnswer => '看答案';

  @override
  String get revealForfeitTitle => '看答案并认输？';

  @override
  String get revealForfeitBody => '会显示正确答案，本局将计为失败。';
}
