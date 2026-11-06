import 'package:flutter/material.dart';
import '../../features/auth/screens/login_screen.dart';
import '../theme/app_theme.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;

  static void navigateToLogin({String? message}) {
    final ctx = context;
    if (ctx != null) {
      if (message != null && message.isNotEmpty) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: DuoColors.overBudget,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

