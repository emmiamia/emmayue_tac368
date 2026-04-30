import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._prefs) : super(_readInitial(_prefs));

  final SharedPreferences _prefs;

  static const _kTheme = 'wordle_theme_mode';

  static ThemeMode _readInitial(SharedPreferences p) {
    final v = p.getString(_kTheme);
    return switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.dark,
    };
  }

  Future<void> setTheme(ThemeMode mode) async {
    emit(mode);
    await _prefs.setString(_kTheme, mode.name);
  }

  /// Switches between light and dark (persisted).
  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setTheme(next);
  }
}
