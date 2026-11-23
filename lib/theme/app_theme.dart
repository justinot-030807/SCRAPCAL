import 'package:flutter/material.dart';

class AppColors {
  // Soft light-green background that reduces glare outdoors while keeping high contrast
  static const Color scaffold = Color(0xFFF2FBF5);
  static const Color surface = Color(0xFFFFFFFF);

  // Light green accents for active/quick-add surfaces
  static const Color lightGreenBg = Color(0xFFDCFCE7);
  static const Color lightGreenSurface = Color(0xFFE8F8EE);
  static const Color lightGreenBorder = Color(0xFF86EFAC);

  // Deep forest & emerald greens for high-contrast buttons and headers
  static const Color primaryGreen = Color(0xFF15803D);
  static const Color primaryGreenDark = Color(0xFF14532D);
  static const Color mediumGreen = Color(0xFF16A34A);

  // Tactile key surfaces
  static const Color keySecondary = Color(0xFFDCFCE7);
  static const Color keyPressed = Color(0xFFBBF7D0);

  // High-contrast ink colors for older eyes
  static const Color ink = Color(0xFF0F172A);
  static const Color inkSecondary = Color(0xFF1E3A2F);
  static const Color inkMuted = Color(0xFF475569);

  // Clear borders so every button and box is easy to distinguish
  static const Color border = Color(0xFFBBF7D0);
  static const Color borderStrong = Color(0xFF4ADE80);
  static const Color keyBorder = Color(0xFFCBD5E1);

  // Clear red for Bura / Delete / Reset
  static const Color danger = Color(0xFFB91C1C);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFCA5A5);

  // Distinct Amber/Orange for SAVE / TAPOS NA finalize action
  static const Color saveAmber = Color(0xFFD97706);
  static const Color saveAmberDark = Color(0xFFB45309);

  static const Color accentGreen = Color(0xFF15803D);
  static const Color accentGreenBg = Color(0xFFDCFCE7);
}

class AppTheme {
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static TextStyle tabularText({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: tabular,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.scaffold,
      colorScheme: const ColorScheme.light(
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        primary: AppColors.primaryGreen,
        onPrimary: AppColors.surface,
        secondary: AppColors.primaryGreenDark,
        error: AppColors.danger,
      ),
      dividerColor: AppColors.border,
      splashFactory: InkRipple.splashFactory,
      highlightColor: AppColors.keyPressed,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.primaryGreenDark,
        contentTextStyle: TextStyle(
          color: AppColors.surface,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          fontFeatures: tabular,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
