import 'package:flutter/material.dart';

class AppPalette {
  final bool isDark;
  final Color scaffold;
  final Color surface;
  final Color surfaceSubtle;
  final Color headerBg;
  final Color headerBorder;
  final Color headerFg;
  final Color primary;
  final Color primaryDark;
  final Color primarySoftBg;
  final Color primarySoftBorder;
  final Color primarySoftText;
  final Color totalBannerBg;
  final Color totalBannerLabel;
  final Color totalBannerValue;
  final Color ink;
  final Color inkSecondary;
  final Color inkMuted;
  final Color border;
  final Color keyBorder;
  final Color keyDisabledBg;
  final Color keyDisabledFg;
  final Color danger;
  final Color dangerBg;
  final Color dangerBorder;
  final Color saveAmber;
  final Color saveAmberBorder;

  const AppPalette({
    required this.isDark,
    required this.scaffold,
    required this.surface,
    required this.surfaceSubtle,
    required this.headerBg,
    required this.headerBorder,
    required this.headerFg,
    required this.primary,
    required this.primaryDark,
    required this.primarySoftBg,
    required this.primarySoftBorder,
    required this.primarySoftText,
    required this.totalBannerBg,
    required this.totalBannerLabel,
    required this.totalBannerValue,
    required this.ink,
    required this.inkSecondary,
    required this.inkMuted,
    required this.border,
    required this.keyBorder,
    required this.keyDisabledBg,
    required this.keyDisabledFg,
    required this.danger,
    required this.dangerBg,
    required this.dangerBorder,
    required this.saveAmber,
    required this.saveAmberBorder,
  });

  static const AppPalette light = AppPalette(
    isDark: false,
    scaffold: Color(0xFFF2FBF5),
    surface: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFE8F8EE),
    headerBg: Color(0xFF15803D),
    headerBorder: Color(0xFF14532D),
    headerFg: Color(0xFFFFFFFF),
    primary: Color(0xFF15803D),
    primaryDark: Color(0xFF14532D),
    primarySoftBg: Color(0xFFDCFCE7),
    primarySoftBorder: Color(0xFF86EFAC),
    primarySoftText: Color(0xFF14532D),
    totalBannerBg: Color(0xFF14532D),
    totalBannerLabel: Color(0xFFDCFCE7),
    totalBannerValue: Color(0xFFFFFFFF),
    ink: Color(0xFF0F172A),
    inkSecondary: Color(0xFF1E3A2F),
    inkMuted: Color(0xFF475569),
    border: Color(0xFFBBF7D0),
    keyBorder: Color(0xFFCBD5E1),
    keyDisabledBg: Color(0xFFF1F5F9),
    keyDisabledFg: Color(0xFFCBD5E1),
    danger: Color(0xFFB91C1C),
    dangerBg: Color(0xFFFEF2F2),
    dangerBorder: Color(0xFFFCA5A5),
    saveAmber: Color(0xFFD97706),
    saveAmberBorder: Color(0xFFB45309),
  );

  static const AppPalette dark = AppPalette(
    isDark: true,
    scaffold: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceSubtle: Color(0xFF18241D),
    headerBg: Color(0xFF14532D),
    headerBorder: Color(0xFF2A2A2A),
    headerFg: Color(0xFFFAFAFA),
    primary: Color(0xFF16A34A),
    primaryDark: Color(0xFF15803D),
    primarySoftBg: Color(0xFF192B20),
    primarySoftBorder: Color(0xFF2A4A35),
    primarySoftText: Color(0xFF86EFAC),
    totalBannerBg: Color(0xFF14532D),
    totalBannerLabel: Color(0xFFBBF7D0),
    totalBannerValue: Color(0xFFFAFAFA),
    ink: Color(0xFFFAFAFA),
    inkSecondary: Color(0xFFD4D4D8),
    inkMuted: Color(0xFFA1A1AA),
    border: Color(0xFF2A2A2A),
    keyBorder: Color(0xFF2A2A2A),
    keyDisabledBg: Color(0xFF161616),
    keyDisabledFg: Color(0xFF3F3F46),
    danger: Color(0xFFF87171),
    dangerBg: Color(0xFF2C1616),
    dangerBorder: Color(0xFF5C2424),
    saveAmber: Color(0xFFD97706),
    saveAmberBorder: Color(0xFFB45309),
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

class AppTheme {
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static TextStyle tabularText({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    Color color = const Color(0xFF0F172A),
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

  static ThemeData buildTheme(AppPalette p) {
    final brightness = p.isDark ? Brightness.dark : Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.scaffold,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.primary,
        onPrimary: const Color(0xFFFFFFFF),
        secondary: p.primaryDark,
        onSecondary: const Color(0xFFFFFFFF),
        error: p.danger,
        onError: const Color(0xFFFFFFFF),
        surface: p.surface,
        onSurface: p.ink,
      ),
      dividerColor: p.border,
      splashFactory: InkRipple.splashFactory,
      highlightColor: p.primarySoftBg,
      appBarTheme: AppBarTheme(
        backgroundColor: p.headerBg,
        foregroundColor: p.headerFg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.isDark ? const Color(0xFF27272A) : p.primaryDark,
        contentTextStyle: const TextStyle(
          color: Color(0xFFFAFAFA),
          fontSize: 15,
          fontWeight: FontWeight.w700,
          fontFeatures: tabular,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get lightTheme => buildTheme(AppPalette.light);
  static ThemeData get darkTheme => buildTheme(AppPalette.dark);
}
