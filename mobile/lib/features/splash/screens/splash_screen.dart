import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/storage/auth_storage.dart';
import '../../navigation/screens/main_navigation_screen.dart';
import '../../onboarding/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    _timer = Timer(const Duration(milliseconds: 1800), () async {
      if (!mounted) return;
      final hasToken = await AuthStorage.isLoggedIn();
      bool isAuthenticated = false;

      if (hasToken) {
        // Verify access token or attempt automatic refresh
        final res = await ApiService.get(ApiConstants.profile, retry: true);
        if (res.success) {
          isAuthenticated = true;
        } else if (res.statusCode == 401) {
          // Token is invalid/expired and refresh failed: clear storage
          await AuthStorage.clearAuth();
          isAuthenticated = false;
        } else {
          // Offline / network issue: retain session to allow offline SQLite cache access
          isAuthenticated = true;
        }
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              isAuthenticated ? const MainNavigationScreen() : const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DuoColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Duo Original Brand Logo (Vertical with Emblem, Wordmark & Tagline)
                Image.asset(
                  'assets/icons/DUO_vertical.png',
                  width: 220,
                  fit: BoxFit.contain,
                  semanticLabel: 'DUO - Money Managed. Tasks Shared.',
                ),
                const SizedBox(height: 48),

                // Loading Indicator
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: DuoColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
