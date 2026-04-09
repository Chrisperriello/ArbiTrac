import 'package:flutter/material.dart';

import 'core/theme/cyber_arb_theme.dart';
import 'core/theme/quant_theme.dart';

enum AppThemeId { dark, quant, cyber }

extension AppThemeIdX on AppThemeId {
  String get storageValue => switch (this) {
    AppThemeId.dark => 'dark',
    AppThemeId.quant => 'quant',
    AppThemeId.cyber => 'cyber',
  };

  String get displayName => switch (this) {
    AppThemeId.dark => 'Dark Mode',
    AppThemeId.quant => 'Quant Mode',
    AppThemeId.cyber => 'Cyber Mode',
  };

  static AppThemeId fromStorageValue(String? value) {
    return switch (value) {
      'dark' => AppThemeId.dark,
      'cyber' => AppThemeId.cyber,
      _ => AppThemeId.quant,
    };
  }
}

class AppThemeRegistry {
  static ThemeData resolve(AppThemeId themeId) {
    return switch (themeId) {
      AppThemeId.dark => _darkTheme,
      AppThemeId.quant => QuantTheme.theme,
      AppThemeId.cyber => CyberArbTheme.theme,
    };
  }

  static ThemeData get _darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF5C6BC0),
        secondary: Color(0xFF7986CB),
        surface: Color(0xFF1E1E1E),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      cardTheme: const CardThemeData(elevation: 1, margin: EdgeInsets.zero),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(height: 1.35),
      ),
    );
  }
}
