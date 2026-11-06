import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/models/task_model.dart';
import '../../../core/network/dashboard_service.dart';
import '../../../core/network/task_service.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/budget_alert_badge.dart';
import '../../expenses/screens/add_expense_screen.dart';
import '../../tasks/screens/add_task_screen.dart';
import '../../budgets/screens/budget_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  DashboardData? _apiDashboard;
  Map<String, dynamic>? _localUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadRealData();
  }

  Future<void> _loadUser() async {
    final u = await AuthStorage.getUserData();
    if (mounted) {
      setState(() => _localUser = u);
    }
  }

  Future<void> _loadRealData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await DashboardService.getDashboardData();
      if (mounted) {
        setState(() {
          _apiDashboard = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load dashboard data. Pull to refresh.';
        });
      }
    }
  }

  Future<void> _toggleTaskStatus(TaskModel task) async {
    final res = await TaskService.toggleTask(task.id);
    if (res.success && mounted) {
      _loadRealData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawName = _apiDashboard?.user?['name']?.toString() ??
        _localUser?['name']?.toString() ??
        'User';
    final firstName = rawName.trim().isNotEmpty ? rawName.trim().split(' ').first : 'User';

    final recentExpenses = _apiDashboard?.recentExpenses ?? [];
    final todayTasks = _apiDashboard?.todayTasks ?? [];
    final upcomingTasks = _apiDashboard?.upcomingTasks ?? [];
    final analytics = _apiDashboard?.spendingAnalytics ?? [];
    final completedCount = _apiDashboard?.completedCount ?? 0;
    final pendingCount = _apiDashboard?.pendingCount ?? 0;

    return Scaffold(
      backgroundColor: DuoColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DuoColors.lavenderBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: DuoColors.primary.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(5),
              child: Image.asset(
                'assets/icons/DUO_icon-only.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $firstName 👋',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Money Managed. Tasks Shared.',
                    style: TextStyle(fontSize: 11, color: DuoColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadRealData,
        color: DuoColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading) ...[
                const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  child: LinearProgressIndicator(color: DuoColors.primary, minHeight: 2.5),
                ),
                const SizedBox(height: 12),
              ],

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DuoColors.overBudget.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DuoColors.overBudget.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: DuoColors.overBudget, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: DuoColors.overBudget)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18, color: DuoColors.overBudget),
                        onPressed: _loadRealData,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 1. Monthly Budget Summary & Spending Progress
              _buildMonthlyBudgetCard(),
              const SizedBox(height: 18),

              // 2. Quick Actions Row
              _buildQuickActions(),
              const SizedBox(height: 20),

              // 3. Task Overview Counter Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Pending Tasks',
                      value: pendingCount.toString(),
                      icon: Icons.pending_actions_rounded,
                      color: DuoColors.warning80,
                      onTap: () => widget.onNavigateTab?.call(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Completed Tasks',
                      value: completedCount.toString(),
                      icon: Icons.task_alt_rounded,
                      color: DuoColors.success,
                      onTap: () => widget.onNavigateTab?.call(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Today's Tasks Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text("Today's Tasks", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: DuoColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${todayTasks.length}',
                          style: const TextStyle(color: DuoColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => widget.onNavigateTab?.call(2),
                    child: const Text('View Tasks', style: TextStyle(color: DuoColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTodayTasksList(todayTasks),
              const SizedBox(height: 24),

              // 5. Upcoming Tasks Section
              if (upcomingTasks.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Upcoming Tasks', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => widget.onNavigateTab?.call(2),
                      child: const Text('All Tasks', style: TextStyle(color: DuoColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildUpcomingTasksList(upcomingTasks),
                const SizedBox(height: 24),
              ],

              // 6. Monthly Spending Analytics Section
              if (analytics.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Monthly Spending Analytics', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => widget.onNavigateTab?.call(1),
                      child: const Text('Money Tab', style: TextStyle(color: DuoColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildSpendingAnalyticsCard(analytics),
                const SizedBox(height: 24),
              ],

              // 7. Recent Expenses Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Expenses', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => widget.onNavigateTab?.call(1),
                    child: const Text('View All', style: TextStyle(color: DuoColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildRecentExpensesList(recentExpenses),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DuoColors.lavenderBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: DuoColors.textPrimary),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: DuoColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBudgetCard() {
    final BudgetModel? apiBudget = _apiDashboard?.budget;

    final limit = apiBudget?.amountLimit ?? 0.0;
    final totalSpent = apiBudget?.totalSpent ?? 0.0;
    final remaining = apiBudget?.remaining ?? 0.0;
    final percentage = limit > 0 ? (totalSpent / limit * 100) : 0.0;
    final alertLevel = apiBudget?.alertLevel ?? (limit <= 0 ? 'NO_BUDGET_SET' : 'SAFE');
    final alertMessage = apiBudget?.alertMessage ?? '';

    final progress = limit > 0 ? (totalSpent / limit).clamp(0.0, 1.0) : 0.0;

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BudgetScreen()),
        );
        _loadRealData();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DuoColors.lavenderSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DuoColors.lavenderBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: DuoColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Monthly Budget',
                      style: TextStyle(fontWeight: FontWeight.bold, color: DuoColors.primary, fontSize: 13.5),
                    ),
                  ],
                ),
                BudgetAlertBadge(
                  alertLevel: alertLevel,
                  percentage: percentage,
                  isCompact: true,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > 100
                      ? DuoColors.overBudget
                      : (percentage >= 100
                          ? DuoColors.limit100
                          : (percentage >= 80 ? DuoColors.warning80 : DuoColors.primary)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Numbers Row
            Row(
              children: [
                _buildStatItem('Spent', DuoFormatters.formatCurrency(totalSpent), DuoColors.overBudget),
                _buildStatItem(
                  percentage > 100 ? 'Over By' : 'Remaining',
                  DuoFormatters.formatCurrency(percentage > 100 ? (totalSpent - limit) : remaining),
                  percentage > 100 ? DuoColors.overBudget : DuoColors.success,
                ),
                _buildStatItem('Allowance', limit > 0 ? DuoFormatters.formatCurrency(limit) : 'Not Set', DuoColors.primary),
              ],
            ),

            if (percentage >= 80 && alertMessage.isNotEmpty) ...[
              const SizedBox(height: 14),
              BudgetAlertBadge(
                alertLevel: alertLevel,
                percentage: percentage,
                message: alertMessage,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: DuoColors.textSecondary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionTile(
            title: 'Add Expense',
            subtitle: 'Track spending',
            icon: Icons.add_card_rounded,
            onTap: () async {
              final added = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
              );
              if (added == true) _loadRealData();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionTile(
            title: 'Add Task',
            subtitle: 'Personal to-do',
            icon: Icons.add_task_rounded,
            onTap: () async {
              final added = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const AddTaskScreen()),
              );
              if (added == true) _loadRealData();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DuoColors.lavenderSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: DuoColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: DuoColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpendingAnalyticsCard(List<CategoryAnalytics> list) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: list.map((item) {
            final color = DuoFormatters.colorForCategory(item.category);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(DuoFormatters.iconForCategory(item.category), size: 16, color: color),
                          const SizedBox(width: 8),
                          Text(item.category, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      Text(
                        '${DuoFormatters.formatCurrency(item.total)} (${item.percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (item.percentage / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: DuoColors.lavenderBorder.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRecentExpensesList(List<ExpenseModel> list) {
    if (list.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No expenses logged yet this month.',
              style: TextStyle(color: DuoColors.textSecondary, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: list.take(5).map((exp) {
          final color = DuoFormatters.colorForCategory(exp.category);
          return ListTile(
            onTap: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => AddExpenseScreen(expenseToEdit: exp)),
              );
              if (updated == true) _loadRealData();
            },
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(DuoFormatters.iconForCategory(exp.category), color: color, size: 20),
            ),
            title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(
              '${exp.category} • ${exp.paymentMethod} • ${DuoFormatters.formatShortDate(exp.expenseDate)}',
              style: const TextStyle(fontSize: 11.5, color: DuoColors.textSecondary),
            ),
            trailing: Text(
              '- ${DuoFormatters.formatCurrency(exp.amount)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: DuoColors.overBudget, fontSize: 14),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTodayTasksList(List<TaskModel> list) {
    if (list.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Center(
            child: Text(
              'All clear for today! No pending tasks due today.',
              style: TextStyle(color: DuoColors.textSecondary, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: list.map((task) {
          return CheckboxListTile(
            activeColor: DuoColors.primary,
            value: task.isDone,
            onChanged: (_) => _toggleTaskStatus(task),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                decoration: task.isDone ? TextDecoration.lineThrough : null,
                color: task.isDone ? DuoColors.textMuted : DuoColors.textPrimary,
              ),
            ),
            subtitle: Row(
              children: [
                _buildPriorityBadge(task.priority),
                const SizedBox(width: 8),
                if (task.dueDate != null)
                  Text(
                    'Due ${DuoFormatters.formatShortDate(DateTime.tryParse(task.dueDate!) ?? DateTime.now())}',
                    style: const TextStyle(fontSize: 11, color: DuoColors.textSecondary),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUpcomingTasksList(List<TaskModel> list) {
    return Card(
      child: Column(
        children: list.take(4).map((task) {
          return ListTile(
            onTap: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => AddTaskScreen(taskToEdit: task)),
              );
              if (updated == true) _loadRealData();
            },
            leading: IconButton(
              icon: Icon(
                task.isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: task.isDone ? DuoColors.success : DuoColors.textMuted,
                size: 22,
              ),
              onPressed: () => _toggleTaskStatus(task),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                decoration: task.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Row(
              children: [
                _buildPriorityBadge(task.priority),
                const SizedBox(width: 8),
                if (task.dueDate != null)
                  Text(
                    'Due ${DuoFormatters.formatShortDate(DateTime.tryParse(task.dueDate!) ?? DateTime.now())}',
                    style: const TextStyle(fontSize: 11, color: DuoColors.textSecondary),
                  ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: DuoColors.textMuted),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color bg;
    Color fg;
    switch (priority.toUpperCase()) {
      case 'HIGH':
        bg = DuoColors.overBudget.withValues(alpha: 0.12);
        fg = DuoColors.overBudget;
        break;
      case 'LOW':
        bg = DuoColors.mintAccent.withValues(alpha: 0.5);
        fg = DuoColors.success;
        break;
      default:
        bg = DuoColors.warning80.withValues(alpha: 0.14);
        fg = DuoColors.warning80;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority,
        style: TextStyle(color: fg, fontSize: 10.5, fontWeight: FontWeight.bold),
      ),
    );
  }
}
