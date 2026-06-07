import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme — Sistem visual premium terpusat untuk GoGrow.
class AppTheme {
  AppTheme._();

  // ─── Warna Utama ─────────────────────────────────────────────────────────
  static const Color bg         = Color(0xFF080B10);
  static const Color surface    = Color(0xFF111318);
  static const Color surfaceAlt = Color(0xFF181C23);
  static const Color surfaceHigh= Color(0xFF1E232C);

  static const Color accent     = Color(0xFF00E676);   // Hijau vibrant
  static const Color accentDim  = Color(0xFF00E67620);
  static const Color accentGlow = Color(0xFF00E67640);
  static const Color accentDark = Color(0xFF00C853);

  static const Color purple     = Color(0xFF7C4DFF);
  static const Color purpleDim  = Color(0xFF7C4DFF20);
  static const Color blue       = Color(0xFF2979FF);
  static const Color blueDim    = Color(0xFF2979FF20);
  static const Color cyan       = Color(0xFF00E5FF);
  static const Color cyanDim    = Color(0xFF00E5FF20);
  static const Color orange     = Color(0xFFFF6D00);
  static const Color orangeDim  = Color(0xFFFF6D0020);
  static const Color danger     = Color(0xFFFF1744);
  static const Color dangerDim  = Color(0xFFFF174420);
  static const Color warning    = Color(0xFFFFAB00);
  static const Color info       = Color(0xFF2979FF);

  // ─── Warna Teks ──────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF0F2F5);
  static const Color textSecondary = Color(0xFF8A9AB5);
  static const Color textMuted     = Color(0xFF4A5568);
  static const Color textDisabled  = Color(0xFF2D3748);

  // ─── Border ──────────────────────────────────────────────────────────────
  static const Color borderSubtle = Color(0xFF1A2030);
  static const Color borderMedium = Color(0xFF242C3D);

  // ─── Gradients ───────────────────────────────────────────────────────────
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00BFA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF1744), Color(0xFFFF6D00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF080B10), Color(0xFF0D1117)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const RadialGradient accentRadialGlow = RadialGradient(
    colors: [Color(0xFF00E67630), Color(0x00000000)],
    radius: 0.8,
  );

  // ─── Radius ──────────────────────────────────────────────────────────────
  static const double radiusS  = 10.0;
  static const double radiusM  = 16.0;
  static const double radiusL  = 20.0;
  static const double radiusXL = 28.0;

  // ─── Spacing ─────────────────────────────────────────────────────────────
  static const double pagePadding  = 20.0;
  static const double itemSpacing  = 12.0;

  // ─── Animasi ─────────────────────────────────────────────────────────────
  static const Duration durationFast   = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow   = Duration(milliseconds: 600);
  static const Curve curveSnappy       = Curves.easeOutCubic;
  static const Curve curveElastic      = Curves.elasticOut;
  static const Curve curveSoft         = Curves.easeInOutCubic;

  // ─── Shadows ─────────────────────────────────────────────────────────────
  static List<BoxShadow> glowShadow(Color color, {double blur = 20, double spread = 0}) => [
    BoxShadow(color: color.withOpacity(0.35), blurRadius: blur, spreadRadius: spread),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4)),
  ];

  // ─── Priority Colors ─────────────────────────────────────────────────────
  static Color priorityColor(String priority) {
    switch (priority) {
      case 'High':   return danger;
      case 'Medium': return warning;
      default:       return info;
    }
  }

  static LinearGradient priorityGradient(String priority) {
    switch (priority) {
      case 'High':   return dangerGradient;
      case 'Medium': return LinearGradient(colors: [warning, orange]);
      default:       return purpleGradient;
    }
  }

  // ─── Habit Colors ────────────────────────────────────────────────────────
  static Color habitColor(String? color) {
    switch (color) {
      case 'blue':   return blue;
      case 'orange': return orange;
      case 'red':    return danger;
      case 'purple': return purple;
      case 'cyan':   return cyan;
      default:       return accent;
    }
  }

  static LinearGradient habitGradient(String? color) {
    switch (color) {
      case 'blue':   return purpleGradient;
      case 'orange': return LinearGradient(colors: [orange, warning]);
      case 'red':    return dangerGradient;
      case 'purple': return purpleGradient;
      default:       return accentGradient;
    }
  }

  // ─── Text Styles ─────────────────────────────────────────────────────────
  static TextStyle get headingLarge => GoogleFonts.inter(
    color: textPrimary, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.8,
  );

  static TextStyle get headingMedium => GoogleFonts.inter(
    color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    color: textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    color: textSecondary, fontSize: 13, height: 1.6,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    color: textMuted, fontSize: 12, height: 1.5,
  );

  static TextStyle get captionStyle => GoogleFonts.inter(
    color: textMuted, fontSize: 11, letterSpacing: 0.2,
  );

  // ─── ThemeData ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    primaryColor: accent,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: purple,
      surface: surface,
      error: danger,
    ),
    appBarTheme: const AppBarTheme(backgroundColor: bg, elevation: 0),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: accent,
      labelStyle: GoogleFonts.inter(fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusS)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceAlt,
      hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusM), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusM), borderSide: const BorderSide(color: borderSubtle)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radiusM), borderSide: const BorderSide(color: accent, width: 1.5)),
    ),
  );
}