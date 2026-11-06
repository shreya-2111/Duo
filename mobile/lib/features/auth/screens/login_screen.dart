import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_service.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../shared/widgets/duo_button.dart';
import '../../navigation/screens/main_navigation_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'alex.sharma@duo.app');
  final _passwordController = TextEditingController(text: 'password123');
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final res = await ApiService.post(
        ApiConstants.login,
        {'email': email, 'password': password},
        withAuth: false,
      );

      if (res.success && res.data is Map) {
        final data = res.data as Map;
        final tokens = data['tokens'] is Map ? (data['tokens'] as Map) : null;
        final user = data['user'] is Map ? (data['user'] as Map) : null;

        if (tokens != null && user != null) {
          final userMap = Map<String, dynamic>.from(user);
          await AuthStorage.saveAuthData(
            accessToken: tokens['access']?.toString() ?? '',
            refreshToken: tokens['refresh']?.toString() ?? '',
            user: userMap,
          );
          final userName = userMap['name']?.toString() ?? 'User';

          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text('✨ Welcome back, $userName!'),
              backgroundColor: DuoColors.success,
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
          return;
        }
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(res.errorMessage ?? 'Invalid email or password. Please try again.'),
          backgroundColor: DuoColors.overBudget,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Connection error: $e. Please verify backend is running on 127.0.0.1:8000.'),
          backgroundColor: DuoColors.overBudget,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showExitDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: DuoColors.primary, size: 24),
            SizedBox(width: 10),
            Text('Exit Duo?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: DuoColors.textPrimary)),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit the application?',
          style: TextStyle(color: DuoColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: DuoColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DuoColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          final exit = await _showExitDialog();
          if (exit && mounted) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: DuoColors.background,
        body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Duo Original Brand Logo (Vertical)
                Image.asset(
                  'assets/icons/DUO_vertical.png',
                  width: 180,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 28),

                // Form Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: DuoColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Log in to view your private budget and shared tasks.',
                          style: TextStyle(fontSize: 13, color: DuoColors.textSecondary),
                        ),
                        const SizedBox(height: 22),

                        const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'name@example.com',
                            prefixIcon: Icon(Icons.email_outlined, color: DuoColors.primary),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                );
                              },
                              child: const Text(
                                'Forgot?',
                                style: TextStyle(
                                  color: DuoColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline, color: DuoColors.primary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: DuoColors.textMuted,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        DuoButton(
                          title: 'Sign In',
                          isLoading: _isLoading,
                          onPressed: _handleLogin,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ", style: TextStyle(color: DuoColors.textSecondary)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'Create Account',
                        style: TextStyle(color: DuoColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
