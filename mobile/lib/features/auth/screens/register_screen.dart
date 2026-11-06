import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_service.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../shared/widgets/duo_button.dart';
import '../../navigation/screens/main_navigation_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final res = await ApiService.post(
        ApiConstants.register,
        {'name': name, 'email': email, 'password': password},
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
          final userName = userMap['name']?.toString() ?? name;

          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text('🎉 Account created! Welcome, $userName!'),
              backgroundColor: DuoColors.success,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            (route) => false,
          );
          return;
        }
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(res.errorMessage ?? 'Registration failed. Please try a different email.'),
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

  bool get _hasUnsavedChanges =>
      _nameController.text.trim().isNotEmpty ||
      _emailController.text.trim().isNotEmpty ||
      _passwordController.text.isNotEmpty;

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: DuoColors.warning80, size: 24),
            SizedBox(width: 8),
            Text('Discard Registration?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'You have entered details for creating an account. Are you sure you want to discard them and go back to Sign In?',
          style: TextStyle(color: DuoColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Editing', style: TextStyle(color: DuoColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DuoColors.overBudget,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _confirmDiscardChanges();
        if (discard && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: DuoColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back to Sign In',
            onPressed: () async {
              final discard = await _confirmDiscardChanges();
              if (discard && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Image.asset(
            'assets/icons/DUO_horizontal.png',
            height: 32,
            fit: BoxFit.contain,
          ),
        ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: DuoColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Manage your finances privately and stay productive with Duo.',
                      style: TextStyle(fontSize: 13, height: 1.4, color: DuoColors.textSecondary),
                    ),
                    const SizedBox(height: 22),

                    const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Alex Sharma',
                        prefixIcon: Icon(Icons.person_outline, color: DuoColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'alex.sharma@duo.app',
                        prefixIcon: Icon(Icons.email_outlined, color: DuoColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Password (6+ characters)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
                      title: 'Create Account',
                      isLoading: _isLoading,
                      onPressed: _handleRegister,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
