import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/network/budget_service.dart';
import '../../../core/network/expense_service.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/budget_alert_badge.dart';
import '../../../shared/widgets/duo_button.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  DateTime? _selectedDate;
  DateTime get selectedDate => _selectedDate ?? DateTime.now();
  final _amountController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  BudgetModel? _budget;
  MonthlySummaryModel? _summary;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadBudgetData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadBudgetData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final curDate = selectedDate;
      final results = await Future.wait([
        BudgetService.getCurrentBudget(
          month: curDate.month,
          year: curDate.year,
        ),
        ExpenseService.getMonthlySummary(
          month: curDate.month,
          year: curDate.year,
        ),
      ]);

      if (mounted) {
        setState(() {
          _budget = results[0] as BudgetModel;
          _summary = results[1] as MonthlySummaryModel?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load budget details. Please check your network.';
        });
      }
    }
  }

  void _previousMonth() {
    final curDate = selectedDate;
    setState(() {
      _selectedDate = DateTime(curDate.year, curDate.month - 1);
    });
    _loadBudgetData();
  }

  void _nextMonth() {
    final curDate = selectedDate;
    setState(() {
      _selectedDate = DateTime(curDate.year, curDate.month + 1);
    });
    _loadBudgetData();
  }

  void _openSetBudgetDialog() {
    final curDate = selectedDate;
    _amountController.text = _budget != null && _budget!.amountLimit > 0
        ? _budget!.amountLimit.toStringAsFixed(0)
        : '35000';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set ${_monthName(curDate.month)} ${curDate.year} Budget',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Define your personal monthly spending target. Non-blocking alerts trigger at 80%, 100%, and above.',
              style: TextStyle(fontSize: 13, color: DuoColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                hintText: '35000',
              ),
            ),
            const SizedBox(height: 20),
            DuoButton(
              title: 'Save Monthly Budget',
              onPressed: () async {
                final amt = double.tryParse(_amountController.text.trim());
                if (amt == null || amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an amount greater than 0.')),
                  );
                  return;
                }

                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);

                final token = await AuthStorage.getAccessToken();
                if (token == null || token.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ You are not logged in. Please sign in to set budgets.'),
                      backgroundColor: DuoColors.overBudget,
                    ),
                  );
                  return;
                }

                navigator.pop();
                setState(() => _isLoading = true);

                try {
                  final res = await BudgetService.setBudget(
                    month: curDate.month,
                    year: curDate.year,
                    amountLimit: amt,
                  );

                  if (res.success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✨ Monthly budget saved successfully!'),
                        backgroundColor: DuoColors.success,
                      ),
                    );
                    _loadBudgetData();
                  } else if (mounted) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res.errorMessage ?? 'Failed to update budget limit.'),
                        backgroundColor: DuoColors.overBudget,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving budget: $e'),
                        backgroundColor: DuoColors.overBudget,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final curDate = selectedDate;
    final monthName = _monthName(curDate.month);
    final limit = _budget?.amountLimit ?? 0.0;
    final totalSpent = _summary?.totalSpent ?? (_budget?.totalSpent ?? 0.0);
    final progress = limit > 0 ? (totalSpent / limit).clamp(0.0, 1.0) : 0.0;
    final percentage = limit > 0 ? (totalSpent / limit * 100) : 0.0;
    final remaining = limit > totalSpent ? (limit - totalSpent) : 0.0;
    final overSpent = totalSpent > limit ? (totalSpent - limit) : 0.0;
    final alertLevel = _budget?.alertLevel ??
        (limit <= 0
            ? 'NO_BUDGET_SET'
            : (percentage > 100
                ? 'OVER_BUDGET'
                : (percentage >= 100 ? 'REACHED_100' : (percentage >= 80 ? 'WARNING_80' : 'SAFE'))));

    final categories = _summary?.categories ?? [];
    final comparison = _summary?.comparison;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: DuoColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('$monthName ${curDate.year} Budget'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: DuoColors.primary),
              tooltip: 'Configure Budget Limit',
              onPressed: _openSetBudgetDialog,
            ),
            const SizedBox(width: 8),
          ],
        ),
      body: RefreshIndicator(
        onRefresh: _loadBudgetData,
        color: DuoColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month Selector Bar
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DuoColors.lavenderBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, color: DuoColors.primary),
                      onPressed: _previousMonth,
                    ),
                    Text(
                      '$monthName ${curDate.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, color: DuoColors.primary),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
              ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: DuoColors.primary)),
                )
              else if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: DuoColors.lavenderBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 40, color: DuoColors.textSecondary),
                      const SizedBox(height: 10),
                      Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: DuoColors.textSecondary)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadBudgetData,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              else ...[
                // 1. Main Allowance & Progress Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Monthly Allowance',
                              style: TextStyle(fontSize: 13.5, color: DuoColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              limit > 0 ? DuoFormatters.formatCurrency(limit) : 'Not Configured',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: limit > 0 ? DuoColors.primary : DuoColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 12,
                            backgroundColor: DuoColors.lavenderSurface,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              percentage > 100
                                  ? DuoColors.overBudget
                                  : (percentage >= 100
                                      ? DuoColors.limit100
                                      : (percentage >= 80 ? DuoColors.warning80 : DuoColors.primary)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Spent vs Remaining
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Spent', style: TextStyle(fontSize: 12, color: DuoColors.textSecondary)),
                                  const SizedBox(height: 3),
                                  Text(
                                    DuoFormatters.formatCurrency(totalSpent),
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: DuoColors.overBudget),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    percentage > 100 ? 'Over Budget By' : 'Remaining Budget',
                                    style: const TextStyle(fontSize: 12, color: DuoColors.textSecondary),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    percentage > 100
                                        ? DuoFormatters.formatCurrency(overSpent)
                                        : DuoFormatters.formatCurrency(remaining),
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: percentage > 100 ? DuoColors.overBudget : DuoColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Alert Banner
                        BudgetAlertBadge(
                          alertLevel: alertLevel,
                          percentage: percentage,
                          message: _budget?.alertMessage.isNotEmpty == true
                              ? _budget!.alertMessage
                              : (limit <= 0
                                  ? 'Tap edit above to set your spending limit.'
                                  : null),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Monthly Comparison Card (Requirement 8)
                if (comparison != null) ...[
                  const Text('Monthly Comparison', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (comparison.trend == 'UP' ? DuoColors.overBudget : DuoColors.success)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              comparison.trend == 'UP'
                                  ? Icons.trending_up_rounded
                                  : (comparison.trend == 'DOWN' ? Icons.trending_down_rounded : Icons.trending_flat_rounded),
                              color: comparison.trend == 'UP' ? DuoColors.overBudget : DuoColors.success,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comparison.trend == 'UP'
                                      ? 'Spent more than ${_monthName(comparison.previousMonth)}'
                                      : (comparison.trend == 'DOWN'
                                          ? 'Spent less than ${_monthName(comparison.previousMonth)}'
                                          : 'Same spending as ${_monthName(comparison.previousMonth)}'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Previous: ${DuoFormatters.formatCurrency(comparison.previousSpent)} • Diff: ${DuoFormatters.formatCurrency(comparison.difference.abs())}'
                                  '${comparison.changePercentage != null ? " (${comparison.changePercentage!.abs()}%)" : ""}',
                                  style: const TextStyle(fontSize: 11.5, color: DuoColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 3. Category Spending Breakdown
                const Text('Category Breakdown', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: categories.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'No category spending recorded for this month.',
                                style: TextStyle(color: DuoColors.textSecondary, fontSize: 13),
                              ),
                            ),
                          )
                        : Column(
                            children: categories.map((catItem) {
                              final cat = catItem.category;
                              final total = catItem.total;
                              final catPercent = totalSpent > 0 ? (total / totalSpent) : 0.0;
                              final color = DuoFormatters.colorForCategory(cat);

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(DuoFormatters.iconForCategory(cat), size: 16, color: color),
                                        const SizedBox(width: 8),
                                        Text(cat, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                        const Spacer(),
                                        Text(
                                          DuoFormatters.formatCurrency(total),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '(${catItem.percentage.toStringAsFixed(0)}%)',
                                          style: const TextStyle(fontSize: 11.5, color: DuoColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: catPercent.clamp(0.0, 1.0),
                                        minHeight: 6,
                                        backgroundColor: DuoColors.lavenderSurface,
                                        valueColor: AlwaysStoppedAnimation<Color>(color),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Alert Threshold Rules Reference
                const Text('Alert Threshold Rules', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildRuleTile('80%', 'Early Warning banner triggered at 80% spending', DuoColors.warning80),
                _buildRuleTile('100%', 'Monthly allowance reached banner', DuoColors.limit100),
                _buildRuleTile('>100%', 'Over-budget alert. Expense recording is never blocked!', DuoColors.overBudget),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildRuleTile(String threshold, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DuoColors.lavenderBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              threshold,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(desc, style: const TextStyle(fontSize: 12.5, color: DuoColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }
}
