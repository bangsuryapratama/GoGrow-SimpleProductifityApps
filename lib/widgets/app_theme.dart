import 'package:flutter/material.dart';

/// AppTheme — Konstanta visual terpusat untuk GoGrow.
/// Semua warna, radius, dan style didefinisikan di sini agar mudah diubah.
class AppTheme {
  AppTheme._();

  // ─── Warna Utama ────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF161616);
  static const Color surfaceAlt = Color(0xFF1E1E1E);
  static const Color accent = Color(0xFF00C853);
  static const Color accentDim = Color(0xFF00C85320);
  static const Color danger = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9500);
  static const Color info = Color(0xFF0A84FF);

  // ─── Warna Teks ────────────────────────────────────────────────────────────
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textMuted = Color(0xFF555555);
  static const Color textDisabled = Color(0xFF333333);

  // ─── Border ────────────────────────────────────────────────────────────────
  static const Color borderSubtle = Color(0xFF1F1F1F);
  static const Color borderMedium = Color(0xFF2A2A2A);

  // ─── Radius ────────────────────────────────────────────────────────────────
  static const double radiusS = 10.0;
  static const double radiusM = 16.0;
  static const double radiusL = 20.0;
  static const double radiusXL = 24.0;

  // ─── Padding/Spacing ───────────────────────────────────────────────────────
  static const double pagePadding = 20.0;
  static const double itemSpacing = 12.0;

  // ─── Priority Colors ───────────────────────────────────────────────────────
  static Color priorityColor(String priority) {
    switch (priority) {
      case 'High': return danger;
      case 'Medium': return warning;
      default: return info;
    }
  }

  // ─── Habit Icon Colors ─────────────────────────────────────────────────────
  static Color habitColor(String? color) {
    switch (color) {
      case 'blue': return info;
      case 'orange': return warning;
      case 'red': return danger;
      case 'purple': return const Color(0xFFBF5AF2);
      default: return accent;
    }
  }

  // ─── Text Styles ───────────────────────────────────────────────────────────
  static const TextStyle headingLarge = TextStyle(
    color: textPrimary,
    fontSize: 26,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle headingMedium = TextStyle(
    color: textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle labelSmall = TextStyle(
    color: textMuted,
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
  );

  static const TextStyle bodyMedium = TextStyle(
    color: textSecondary,
    fontSize: 13,
    height: 1.5,
  );

  // ─── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    primaryColor: accent,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      surface: surface,
      error: danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: accent,
      labelStyle: const TextStyle(fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusS)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      hintStyle: const TextStyle(color: Color(0xFF444444), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
    ),
  );
}