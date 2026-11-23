import 'package:flutter/material.dart';

class AppColors {
  static const Color scaffold = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color keySecondary = Color(0xFFF4F4F5);
  static const Color keyPressed = Color(0xFFE4E4E7);
  static const Color ink = Color(0xFF111111);
  static const Color inkSecondary = Color(0xFF52525B);
  static const Color inkMuted = Color(0xFF71717A);
  static const Color border = Color(0xFFE4E4E7);
  static const Color borderStrong = Color(0xFFD4D4D8);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);
  static const Color accentGreen = Color(0xFF15803D);
  static const Color accentGreenBg = Color(0xFFF0FDF4);
}

class AppTheme {
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static TextStyle tabularText({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
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
        primary: AppColors.ink,
        onPrimary: AppColors.surface,
        secondary: AppColors.inkSecondary,
        error: AppColors.danger,
      ),
      dividerColor: AppColors.border,
      splashFactory: NoSplash.splashFactory,
      highlightColor: AppColors.keyPressed,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.scaffold,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(
          color: AppColors.surface,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFeatures: tabular,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
