import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_service.dart';
import '../../../shared/widgets/duo_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _tokenReceived = false;
  bool _isSuccess = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestToken() async {
    final messenger = ScaffoldMessenger.of(context);
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.post(
        ApiConstants.forgotPassword,
        {'email': email},
        withAuth: false,
      );

      if (!mounted) return;

      if (res.success) {
        final token = res.data is Map ? res.data['reset_token']?.toString() : null;
        if (token != null && token.isNotEmpty) {
          _tokenController.text = token;
        }
        setState(() {
          _tokenReceived = true;
          _isLoading = false;
        });
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(res.errorMessage ?? 'Could not generate reset token.'),
            backgroundColor: DuoColors.overBudget,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: DuoColors.overBudget),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResetPassword() async {
    final messenger = ScaffoldMessenger.of(context);
    final email = _emailController.text.trim();
    final token = _tokenController.text.trim();
    final newPassword = _newPasswordController.text;

    if (token.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter the reset token.')),
      );
      return;
    }

    if (newPassword.length < 6) {
      messenger.showSnackBar(
        const SnackBar(content: Text('New password must be at least 6 characters.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.post(
        ApiConstants.resetPassword,
        {
          'email': email,
          'token': token,
          'new_password': newPassword,
        },
        withAuth: false,
      );

      if (!mounted) return;

      if (res.success) {
        setState(() {
          _isSuccess = true;
          _isLoading = false;
        });
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(res.errorMessage ?? 'Failed to reset password.'),
            backgroundColor: DuoColors.overBudget,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: DuoColors.overBudget),
      );
      setState(() => _isLoading = false);
    }
  }

  void _handleBackAction() {
    if (_tokenReceived && !_isSuccess) {
      setState(() => _tokenReceived = false);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackAction();
      },
      child: Scaffold(
        backgroundColor: DuoColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
            onPressed: _handleBackAction,
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
                child: _isSuccess
                    ? _buildSuccessView()
                    : (_tokenReceived ? _buildResetStepView() : _buildEmailStepView()),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildEmailStepView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: DuoColors.lavenderSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DuoColors.lavenderBorder, width: 1.2),
          ),
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            'assets/icons/DUO_icon-only.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: DuoColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Enter your registered email address and we'll issue a secure password reset token.",
          style: TextStyle(fontSize: 13, height: 1.4, color: DuoColors.textSecondary),
        ),
        const SizedBox(height: 24),

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
        const SizedBox(height: 24),

        DuoButton(
          title: 'Generate Reset Token',
          isLoading: _isLoading,
          onPressed: _handleRequestToken,
        ),
      ],
    );
  }

  Widget _buildResetStepView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: DuoColors.mintAccent.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.lock_reset_rounded, color: DuoColors.success),
        ),
        const SizedBox(height: 18),
        const Text(
          'Set New Password',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: DuoColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'A reset token has been issued for ${_emailController.text.trim()}. Enter the token and your new password.',
          style: const TextStyle(fontSize: 13, height: 1.4, color: DuoColors.textSecondary),
        ),
        const SizedBox(height: 20),

        const Text('Reset Token', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: _tokenController,
          decoration: const InputDecoration(
            hintText: 'Enter reset token',
            prefixIcon: Icon(Icons.vpn_key_outlined, color: DuoColors.primary),
          ),
        ),
        const SizedBox(height: 16),

        const Text('New Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline, color: DuoColors.primary),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: DuoColors.textSecondary,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 24),

        DuoButton(
          title: 'Confirm & Reset Password',
          isLoading: _isLoading,
          onPressed: _handleResetPassword,
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: DuoColors.mintAccent.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: DuoColors.success, size: 36),
        ),
        const SizedBox(height: 18),
        const Text(
          'Password Reset!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: DuoColors.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your password has been reset successfully. You can now log in with your new credentials.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.4, color: DuoColors.textSecondary),
        ),
        const SizedBox(height: 26),
        DuoButton(
          title: 'Back to Sign In',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
