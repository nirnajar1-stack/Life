import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Functional portal theme (Stitch assets not in repo — IA-aligned RTL shell).
class PortalColors {
  static const Color primary = Color(0xFF0B3D5C);
  static const Color primarySoft = Color(0xFF145A86);
  static const Color accent = Color(0xFFC45C26);
  static const Color surface = Color(0xFFF3F6F8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF122033);
  static const Color muted = Color(0xFF5B6B7C);
  static const Color line = Color(0xFFD7E0E8);
  static const Color danger = Color(0xFFB42318);
  static const Color warning = Color(0xFFB54708);
  static const Color success = Color(0xFF027A48);
}

class PortalTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: PortalColors.primary,
        surface: PortalColors.surface,
      ).copyWith(
        primary: PortalColors.primary,
        secondary: PortalColors.accent,
        onPrimary: Colors.white,
        outline: PortalColors.line,
      ),
    );

    final textTheme =
        GoogleFonts.heeboTextTheme(base.textTheme).apply(
      bodyColor: PortalColors.ink,
      displayColor: PortalColors.ink,
    );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: PortalColors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: PortalColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: PortalColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: PortalColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PortalColors.line),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.white,
        selectedIconTheme: IconThemeData(color: PortalColors.primary),
        selectedLabelTextStyle: TextStyle(
          color: PortalColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
