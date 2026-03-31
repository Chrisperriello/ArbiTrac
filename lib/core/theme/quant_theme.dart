import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuantTheme {
  static const Color background = Color(0xFF0B101B);
  static const Color surface = Color(0xFF1E2632);
  static const Color profit = Color(0xFF00E676);
  static const Color action = Color(0xFF2979FF);
  static const Color warning = Color(0xFFFFD600);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9E9E9E);

  static ThemeData get theme {
    final monoText = GoogleFonts.robotoMonoTextTheme().apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: action,
        secondary: action,
        surface: surface,
        onSurface: textPrimary,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
      ),
      textTheme: monoText.copyWith(
        bodySmall: monoText.bodySmall?.copyWith(color: textMuted),
        labelMedium: monoText.labelMedium?.copyWith(color: textMuted),
      ),
      dividerColor: textMuted.withValues(alpha: 0.45),
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: background,
        foregroundColor: textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface.withValues(alpha: 0.55),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: textMuted.withValues(alpha: 0.55)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: textMuted.withValues(alpha: 0.55)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: action, width: 1),
        ),
      ),
    );
  }
}
