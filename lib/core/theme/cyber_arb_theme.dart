// Cyber-Arb visual depth uses a true-black base and neon borders (not shadows)
// so dense data surfaces feel like a fast trading terminal.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CyberArbTheme {
  static const Color background = Color(0xFF0F0F0F);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color primary = Color(0xFFBB86FC);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color profitHighlight = Color(0xFFCCFF00);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9E9E9E);

  static ThemeData get theme {
    final baseText = GoogleFonts.robotoMonoTextTheme().apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onSurface: textPrimary,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        error: Colors.redAccent,
      ),
      textTheme: baseText.copyWith(
        bodySmall: baseText.bodySmall?.copyWith(color: textMuted),
        labelMedium: baseText.labelMedium?.copyWith(color: textMuted),
      ),
      dividerColor: textMuted.withValues(alpha: 0.35),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: background,
        foregroundColor: textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: textMuted.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.2),
        ),
      ),
    );
  }
}
