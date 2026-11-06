import 'package:flutter/material.dart';
import 'core/navigation/navigation_service.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DuoApp());
}

class DuoApp extends StatelessWidget {
  const DuoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Duo',
      theme: AppTheme.lightTheme,
      // Design direction: Strictly no dark mode, light lavender and white
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}

