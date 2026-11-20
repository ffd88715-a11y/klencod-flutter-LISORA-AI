import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// TALKORA AI Material 3 Design System (8-point spacing, calm surfaces, no harsh neon).
class TalkoraColors {
  const TalkoraColors._();

  // Light palette
  static const Color lightBackground = Color(0xFFF7F8FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color primaryAccent = Color(0xFF6558F5);
  static const Color secondaryAccent = Color(0xFF8B7CFF);
  static const Color lightMainText = Color(0xFF171923);
  static const Color lightSecondaryText = Color(0xFF85899A);
  static const Color success = Color(0xFF23B77B);
  static const Color error = Color(0xFFEF5B67);

  // Dark palette (calm matte graphite/indigo)
  static const Color darkBackground = Color(0xFF10111A);
  static const Color darkSurface = Color(0xFF191B28);
  static const Color darkCard = Color(0xFF202235);
  static const Color darkPrimary = Color(0xFF8B80FF);
  static const Color darkText = Color(0xFFF4F4FA);
  static const Color darkSecondaryText = Color(0xFFA0A4B8);
}

class TalkoraTheme {
  const TalkoraTheme._();

  static TextTheme _buildTextTheme(TextTheme base, bool isArabic, Color mainText, Color secondaryText) {
    final fontTheme = isArabic ? GoogleFonts.cairoTextTheme(base) : GoogleFonts.interTextTheme(base);
    return fontTheme.copyWith(
      headlineLarge: fontTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700, color: mainText, height: 1.25),
      headlineMedium: fontTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: mainText, height: 1.25),
      titleLarge: fontTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: mainText, height: 1.3),
      titleMedium: fontTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: mainText),
      bodyLarge: fontTheme.bodyLarge?.copyWith(color: mainText, height: 1.5),
      bodyMedium: fontTheme.bodyMedium?.copyWith(color: secondaryText, height: 1.45),
      labelLarge: fontTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  static ThemeData light({required bool isArabic}) {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: TalkoraColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: TalkoraColors.primaryAccent,
        secondary: TalkoraColors.secondaryAccent,
        surface: TalkoraColors.lightSurface,
        error: TalkoraColors.error,
        onPrimary: Colors.white,
        onSurface: TalkoraColors.lightMainText,
      ),
      textTheme: _buildTextTheme(base.textTheme, isArabic, TalkoraColors.lightMainText, TalkoraColors.lightSecondaryText),
      cardTheme: CardThemeData(
        color: TalkoraColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFEAEBF4)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: TalkoraColors.lightBackground,
        foregroundColor: TalkoraColors.lightMainText,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: TalkoraColors.lightSurface,
        indicatorColor: TalkoraColors.primaryAccent.withValues(alpha: 0.14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: TalkoraColors.primaryAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  static ThemeData dark({required bool isArabic}) {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: TalkoraColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: TalkoraColors.darkPrimary,
        secondary: TalkoraColors.secondaryAccent,
        surface: TalkoraColors.darkSurface,
        error: TalkoraColors.error,
        onPrimary: Colors.white,
        onSurface: TalkoraColors.darkText,
      ),
      textTheme: _buildTextTheme(base.textTheme, isArabic, TalkoraColors.darkText, TalkoraColors.darkSecondaryText),
      cardTheme: CardThemeData(
        color: TalkoraColors.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF2B2E45)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: TalkoraColors.darkBackground,
        foregroundColor: TalkoraColors.darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: TalkoraColors.darkSurface,
        indicatorColor: TalkoraColors.darkPrimary.withValues(alpha: 0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: TalkoraColors.darkPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
