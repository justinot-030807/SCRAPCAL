import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/app_strings.dart';
import 'screens/calculator_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.init();
  final isDark = storage.loadDarkMode();
  final palette = isDark ? AppPalette.dark : AppPalette.light;
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: palette.headerBg,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: palette.scaffold,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
    ),
  );
  runApp(ScrapCalApp(storage: storage));
}

class ScrapCalApp extends StatefulWidget {
  final StorageService storage;

  const ScrapCalApp({super.key, required this.storage});

  @override
  State<ScrapCalApp> createState() => _ScrapCalAppState();
}

class _ScrapCalAppState extends State<ScrapCalApp> {
  late AppLanguage _language;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _language = widget.storage.loadLanguage();
    _isDarkMode = widget.storage.loadDarkMode();
  }

  void _updateLanguage(AppLanguage language) {
    setState(() => _language = language);
    widget.storage.saveLanguage(language);
  }

  void _updateDarkMode(bool isDark) {
    setState(() => _isDarkMode = isDark);
    widget.storage.saveDarkMode(isDark);
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: palette.headerBg,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: palette.scaffold,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SCRAPCAL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.10,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: CalculatorScreen(
        storage: widget.storage,
        language: _language,
        isDarkMode: _isDarkMode,
        onLanguageChanged: _updateLanguage,
        onDarkModeChanged: _updateDarkMode,
      ),
    );
  }
}
