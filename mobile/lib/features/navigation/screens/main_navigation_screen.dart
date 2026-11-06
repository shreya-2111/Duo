import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../money/screens/money_screen.dart';
import '../../tasks/screens/my_tasks_screen.dart';
import '../../profile/screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void switchTab(int index) {
    if (mounted && index >= 0 && index < 4) {
      setState(() => _selectedIndex = index);
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
            Text(
              'Exit Duo?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: DuoColors.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit the application?',
          style: TextStyle(color: DuoColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: DuoColors.textSecondary, fontWeight: FontWeight.w600),
            ),
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
    final screens = [
      DashboardScreen(onNavigateTab: switchTab),
      const MoneyScreen(),
      const MyTasksScreen(),
      const ProfileScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_selectedIndex != 0) {
          // If on secondary tab, back gesture/button takes user to Home tab
          switchTab(0);
        } else {
          // If already on Home tab, confirm before closing the application
          final exit = await _showExitDialog();
          if (exit && mounted) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: screens,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: DuoColors.lavenderBorder, width: 0.8)),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: switchTab,
            backgroundColor: Colors.white,
            selectedItemColor: DuoColors.primary,
            unselectedItemColor: DuoColors.textMuted,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Money',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.check_circle_outline_rounded),
                activeIcon: Icon(Icons.check_circle_rounded),
                label: 'Tasks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
