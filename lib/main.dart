import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/calculator_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.scaffold,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.scaffold,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  final storage = await StorageService.init();
  runApp(ScrapCalApp(storage: storage));
}

class ScrapCalApp extends StatelessWidget {
  final StorageService storage;

  const ScrapCalApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SCRAPCAL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: CalculatorScreen(storage: storage),
    );
  }
}
