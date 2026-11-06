import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/storage/auth_storage.dart';
import '../../budgets/screens/budget_screen.dart';
import '../../insights/screens/insights_screen.dart';
import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _budgetAlertsEnabled = true;
  bool _taskRemindersEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthStorage.getUserData();
    if (mounted) {
      setState(() => _user = user);
    }
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: DuoColors.success),
            SizedBox(width: 8),
            Text('Privacy & Security'),
          ],
        ),
        content: const Text(
          '• Your expenses, budgets, and tasks are strictly private to your account.\n\n'
          '• Strict database-level ownership is enforced on all querysets and endpoints.\n\n'
          '• Budget alerts trigger at 80%, 100%, and >100% with no expense creation blocks.\n\n'
          '• Currency is set to INR (₹) and timezone is fixed to Asia/Kolkata.',
          style: TextStyle(fontSize: 13, height: 1.45),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to log out of Duo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: DuoColors.overBudget),
            onPressed: () async {
              final rootNav = Navigator.of(context);
              final dialogNav = Navigator.of(ctx);
              await AuthStorage.clearAuth();
              dialogNav.pop();
              rootNav.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _user?['name']?.toString() ?? 'Duo User';
    final displayEmail = _user?['email']?.toString() ?? 'user@duo.app';

    return Scaffold(
      backgroundColor: DuoColors.background,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Profile Avatar & Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: DuoColors.lavenderSurface,
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: DuoColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      displayEmail,
                      style: const TextStyle(fontSize: 13, color: DuoColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Financial & Insights Shortcuts
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.savings_outlined, color: DuoColors.primary),
                    title: const Text('Monthly Budget & Alerts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Threshold warnings at 80%, 100%, and >100%', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: DuoColors.textMuted),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BudgetScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.insights_rounded, color: DuoColors.primary),
                    title: const Text('Insights & Spending Analytics', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Category charts and monthly comparisons', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: DuoColors.textMuted),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InsightsScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.shield_outlined, color: DuoColors.success),
                    title: const Text('Privacy & Security Architecture', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('100% individual privacy guarantee', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.info_outline, color: DuoColors.textMuted, size: 20),
                    onTap: _showPrivacyDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Notification Preferences
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_outlined, color: DuoColors.primary),
                    title: const Text('Budget Overrun Warnings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Instant alerts when spending crosses 80% and 100%', style: TextStyle(fontSize: 12)),
                    value: _budgetAlertsEnabled,
                    activeThumbColor: DuoColors.primary,
                    onChanged: (val) => setState(() => _budgetAlertsEnabled = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.alarm_on_rounded, color: DuoColors.primary),
                    title: const Text('Task Due Reminders', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Alerts on scheduled task due times', style: TextStyle(fontSize: 12)),
                    value: _taskRemindersEnabled,
                    activeThumbColor: DuoColors.primary,
                    onChanged: (val) => setState(() => _taskRemindersEnabled = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. App Info Card
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Duo',
                    applicationVersion: '2.0.0',
                    applicationLegalese: 'Money Managed. Tasks Shared.',
                    applicationIcon: Image.asset(
                      'assets/icons/DUO_icon-only.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: DuoColors.lavenderSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DuoColors.lavenderBorder, width: 1),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          'assets/icons/DUO_icon-only.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Duo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('Money Managed. Tasks Shared. • v2.0.0', style: TextStyle(fontSize: 12, color: DuoColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.info_outline_rounded, color: DuoColors.textMuted, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 5. Sign Out Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: DuoColors.overBudget),
                  foregroundColor: DuoColors.overBudget,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: _handleLogout,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
