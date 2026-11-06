import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/duo_button.dart';
import '../../auth/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'useLogo': true,
      'badge': '100% PRIVATE FINANCES',
      'title': 'Money Managed Individually',
      'desc': 'Keep your monthly expenses, income and budgets strictly private to your own authenticated account.',
      'color': DuoColors.primary,
    },
    {
      'icon': Icons.task_alt_rounded,
      'badge': 'ORGANIZED PRODUCTIVITY',
      'title': 'Personal Tasks & Reminders',
      'desc': 'Organize your to-dos, set priorities, schedule daily, weekly or monthly repeats, and visualize in list or calendar view.',
      'color': DuoColors.primary,
    },
    {
      'icon': Icons.notifications_active_outlined,
      'badge': 'NON-BLOCKING INTELLIGENCE',
      'title': 'Smart Budget Warnings',
      'desc': 'Stay on track with friendly alerts at 80%, 100%, and over budget. Duo never blocks you from recording an expense.',
      'color': DuoColors.warning80,
    },
  ];

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToAuth();
    }
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentPage > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Scaffold(
        backgroundColor: DuoColors.background,
        appBar: AppBar(
          leading: _currentPage > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Previous',
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                )
              : null,
          title: Image.asset(
            'assets/icons/DUO_horizontal.png',
            height: 32,
            fit: BoxFit.contain,
          ),
        actions: [
          TextButton(
            onPressed: _navigateToAuth,
            child: const Text(
              'Skip',
              style: TextStyle(
                color: DuoColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Card Emblem
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: DuoColors.lavenderSurface,
                            borderRadius: BorderRadius.circular(36),
                            border: Border.all(color: DuoColors.lavenderBorder, width: 1.5),
                          ),
                          child: Center(
                            child: slide['useLogo'] == true
                                ? Image.asset(
                                    'assets/icons/DUO_icon-only.png',
                                    width: 88,
                                    height: 88,
                                    fit: BoxFit.contain,
                                  )
                                : Icon(
                                    slide['icon'] as IconData,
                                    size: 64,
                                    color: slide['color'] as Color,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: DuoColors.lavenderSurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            slide['badge'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: DuoColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: DuoColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        Text(
                          slide['desc'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: DuoColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots Indicator & Next/Get Started Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? DuoColors.primary : DuoColors.lavenderBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  DuoButton(
                    title: _currentPage == _slides.length - 1 ? 'Get Started' : 'Continue',
                    icon: _currentPage == _slides.length - 1 ? Icons.arrow_forward : null,
                    onPressed: _onNext,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

