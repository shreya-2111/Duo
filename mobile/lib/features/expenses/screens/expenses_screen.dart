import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_service.dart';
import '../../../core/storage/local_db.dart';
import '../../../core/utils/formatters.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<dynamic> _expenses = [];
  bool _isLoading = true;
  double _totalExpenses = 0.0;
  final DateTime _currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);

    // 1. First display cached local SQLite data instantly
    final localData = await DuoLocalDb.getExpenses();
    if (localData.isNotEmpty && mounted) {
      setState(() {
        _expenses = localData;
        _totalExpenses = localData.fold<double>(
          0.0,
          (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0),
        );
        _isLoading = false;
      });
    }

    // 2. Fetch fresh remote data from Django REST Framework
    final url = '${ApiConstants.expenses}?month=${_currentMonth.month}&year=${_currentMonth.year}';
    final response = await ApiService.get(url);

    if (response.success && response.data is List && mounted) {
      final remoteList = response.data as List;
      await DuoLocalDb.saveExpenses(remoteList);

      setState(() {
        _expenses = remoteList;
        _totalExpenses = remoteList.fold<double>(
          0.0,
          (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0),
        );
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteExpense(dynamic expense) async {
    final id = expense['id'] ?? expense['remote_id'];
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('Are you sure you want to remove this expense entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: DuoColors.overBudget),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await DuoLocalDb.deleteExpense(id);
    await ApiService.delete('${ApiConstants.expenses}$id/');
    _loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Private Expenses'),
          actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: DuoColors.primary, size: 28),
            onPressed: () async {
              final added = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
              );
              if (added == true) _loadExpenses();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Monthly Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: DuoColors.lavenderSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DuoColors.lavenderBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total This Month', style: TextStyle(color: DuoColors.textSecondary, fontSize: 13)),
                    SizedBox(height: 4),
                    Text('Strictly Private', style: TextStyle(color: DuoColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
                Text(
                  DuoFormatters.formatCurrency(_totalExpenses),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: DuoColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Expenses List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: DuoColors.primary))
                : _expenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long_outlined, size: 50, color: DuoColors.lavenderBorder),
                            const SizedBox(height: 12),
                            const Text('No expenses recorded yet', style: TextStyle(color: DuoColors.textSecondary)),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () async {
                                final added = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                                );
                                if (added == true) _loadExpenses();
                              },
                              icon: const Icon(Icons.add, color: DuoColors.primary),
                              label: const Text('Add your first expense', style: TextStyle(color: DuoColors.primary)),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadExpenses,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _expenses.length,
                          itemBuilder: (context, index) {
                            final item = _expenses[index];
                            final title = item['title'] ?? item['name'] ?? 'Expense';
                            final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
                            final category = item['category']?.toString() ?? 'Other';
                            final dateRaw = item['date']?.toString();
                            final parsedDate = dateRaw != null ? DateTime.tryParse(dateRaw) : null;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: DuoFormatters.colorForCategory(category).withValues(alpha: 0.15),
                                  child: Icon(
                                    DuoFormatters.iconForCategory(category),
                                    color: DuoFormatters.colorForCategory(category),
                                  ),
                                ),
                                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                subtitle: Text(
                                  '$category • ${DuoFormatters.formatDate(parsedDate)}',
                                  style: const TextStyle(fontSize: 12, color: DuoColors.textSecondary),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '- ${DuoFormatters.formatCurrency(amount)}',
                                      style: const TextStyle(
                                        color: DuoColors.overBudget,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: DuoColors.textMuted),
                                      onPressed: () => _deleteExpense(item),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    ),
  );
}
}
