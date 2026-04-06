// Material theme and Coolors palette (coolors.co/ddfff7-93e1d8-ffa69e-aa4465-861657).

import "package:flutter/material.dart";

abstract final class AppPalette {
  static const Color frozenWater = Color(0xFFDDFFF7);
  static const Color pearlAqua = Color(0xFF93E1D8);
  static const Color powderBlush = Color(0xFFFFA69E);
  static const Color berryCrush = Color(0xFFAA4465);
  static const Color darkRaspberry = Color(0xFF861657);
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppPalette.darkRaspberry,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppPalette.darkRaspberry,
    onPrimary: Colors.white,
    primaryContainer: AppPalette.pearlAqua,
    onPrimaryContainer: AppPalette.darkRaspberry,
    secondary: AppPalette.berryCrush,
    onSecondary: Colors.white,
    secondaryContainer: AppPalette.powderBlush,
    onSecondaryContainer: AppPalette.darkRaspberry,
    tertiary: AppPalette.powderBlush,
    tertiaryContainer:
        Color.lerp(AppPalette.powderBlush, Colors.white, 0.55)!,
    onTertiaryContainer: AppPalette.darkRaspberry,
    surface: AppPalette.frozenWater,
    onSurface: AppPalette.darkRaspberry,
    onSurfaceVariant: AppPalette.berryCrush,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow:
        Color.lerp(AppPalette.frozenWater, AppPalette.pearlAqua, 0.35)!,
    surfaceContainer:
        Color.lerp(AppPalette.frozenWater, AppPalette.pearlAqua, 0.2)!,
    outline: AppPalette.berryCrush.withValues(alpha: 0.4),
    outlineVariant: AppPalette.pearlAqua.withValues(alpha: 0.9),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppPalette.frozenWater,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPalette.darkRaspberry,
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.94),
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppPalette.berryCrush,
        disabledForegroundColor: Colors.white70,
        disabledBackgroundColor: AppPalette.berryCrush.withValues(alpha: 0.38),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            BorderSide(color: AppPalette.pearlAqua.withValues(alpha: 0.85)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            BorderSide(color: AppPalette.pearlAqua.withValues(alpha: 0.85)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            const BorderSide(color: AppPalette.darkRaspberry, width: 2),
      ),
    ),
    dividerTheme:
        DividerThemeData(color: AppPalette.pearlAqua.withValues(alpha: 0.6)),
  );
}
