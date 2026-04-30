import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._prefs) : super(_readInitial(_prefs));

  final SharedPreferences _prefs;

  static const _kLocale = 'wordle_locale_code';

  static Locale _readInitial(SharedPreferences p) {
    final c = p.getString(_kLocale);
    if (c == 'zh') return const Locale('zh');
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    emit(locale);
    await _prefs.setString(_kLocale, locale.languageCode);
  }

  Future<void> useEnglish() => setLocale(const Locale('en'));

  Future<void> useChinese() => setLocale(const Locale('zh'));
}
