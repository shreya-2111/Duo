import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/models/budget_model.dart';
import '../../../core/network/expense_service.dart';
import '../../../core/network/budget_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/budget_alert_badge.dart';
import '../../expenses/screens/add_expense_screen.dart';
import '../../budgets/screens/budget_screen.dart';

class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  DateTime _selectedMonth = DateTime.now();
  DateTime get selectedMonth => _selectedMonth;

  String? _selectedCategory;
  String get selectedCategory => _selectedCategory ?? 'All';

  String? _searchQuery;
  String get searchQuery => _searchQuery ?? '';

  DateTimeRange? _selectedDateRange;

  bool _isLoading = true;
  String? _errorMessage;

  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> get expenses => _expenses;
  BudgetModel? _budget;

  final List<String> _categories = [
    'All',
    'Food',
    'Bills',
    'Shopping',
    'Travel',
    'Health',
    'Entertainment',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _selectedCategory = 'All';
    _searchQuery = '';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? startDate;
      String? endDate;
      if (_selectedDateRange != null) {
        startDate = DuoFormatters.apiDate(_selectedDateRange!.start);
        endDate = DuoFormatters.apiDate(_selectedDateRange!.end);
      }

      final currentM = selectedMonth;
      final results = await Future.wait([
        ExpenseService.getExpenses(
          month: _selectedDateRange == null ? currentM.month : null,
          year: _selectedDateRange == null ? currentM.year : null,
          category: selectedCategory,
          search: searchQuery,
          startDate: startDate,
          endDate: endDate,
        ),
        BudgetService.getCurrentBudget(
          month: currentM.month,
          year: currentM.year,
        ),
      ]);

      if (mounted) {
        setState(() {
          _expenses = results[0] as List<ExpenseModel>;
          _budget = results[1] as BudgetModel;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load finances. Please check your network.';
        });
      }
    }
  }

  void _previousMonth() {
    final cur = selectedMonth;
    setState(() {
      _selectedDateRange = null;
      _selectedMonth = DateTime(cur.year, cur.month - 1);
    });
    _loadData();
  }

  void _nextMonth() {
    final cur = selectedMonth;
    setState(() {
      _selectedDateRange = null;
      _selectedMonth = DateTime(cur.year, cur.month + 1);
    });
    _loadData();
  }

  void _resetToCurrentMonth() {
    setState(() {
      _selectedDateRange = null;
      _selectedMonth = DateTime.now();
    });
    _loadData();
  }

  Future<void> _pickDateRange() async {
    final cur = selectedMonth;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime(cur.year, cur.month, 1),
            end: DateTime(cur.year, cur.month + 1, 0),
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: DuoColors.primary,
              onPrimary: Colors.white,
              onSurface: DuoColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _loadData();
    }
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text('Are you sure you want to delete "${expense.title}" (₹${expense.amount.toStringAsFixed(2)})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: DuoColors.overBudget),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await ExpenseService.deleteExpense(expense.id);
      if (res.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted successfully.')),
        );
        _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.errorMessage ?? 'Could not delete expense.'),
            backgroundColor: DuoColors.overBudget,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final curM = selectedMonth;
    final isCurrentMonth = curM.month == DateTime.now().month &&
        curM.year == DateTime.now().year &&
        _selectedDateRange == null;

    final totalSpent = _expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final limit = _budget?.amountLimit ?? 0.0;
    final progress = limit > 0 ? (totalSpent / limit).clamp(0.0, 1.0) : 0.0;
    final percentage = limit > 0 ? (totalSpent / limit * 100) : 0.0;
    final remaining = (limit - totalSpent) > 0 ? (limit - totalSpent) : 0.0;
    final overSpent = totalSpent > limit ? (totalSpent - limit) : 0.0;

    return Scaffold(
      backgroundColor: DuoColors.background,
      appBar: AppBar(
        title: const Text('My Money'),
        actions: [
          IconButton(
            icon: const Icon(Icons.savings_outlined, color: DuoColors.primary),
            tooltip: 'Monthly Budget',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BudgetScreen()),
              );
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: DuoColors.primary, size: 28),
            tooltip: 'Add Expense',
            onPressed: () async {
              final added = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
              );
              if (added == true) {
                _loadData();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: DuoColors.primary,
        child: Column(
          children: [
            // Month Navigation & Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: DuoColors.primary),
                    onPressed: _previousMonth,
                    tooltip: 'Previous Month',
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _selectedDateRange != null
                            ? '${DuoFormatters.formatDate(_selectedDateRange!.start)} - ${DuoFormatters.formatDate(_selectedDateRange!.end)}'
                            : '${_monthName(curM.month)} ${curM.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: DuoColors.primary),
                    onPressed: _nextMonth,
                    tooltip: 'Next Month',
                  ),
                  IconButton(
                    icon: Icon(
                      _selectedDateRange != null ? Icons.date_range_rounded : Icons.calendar_month_outlined,
                      color: _selectedDateRange != null ? DuoColors.primary : DuoColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: _pickDateRange,
                    tooltip: 'Date Range Filter',
                  ),
                  if (!isCurrentMonth)
                    IconButton(
                      icon: const Icon(Icons.today_rounded, color: DuoColors.primary, size: 20),
                      onPressed: _resetToCurrentMonth,
                      tooltip: 'Back to Current Month',
                    ),
                ],
              ),
            ),

            // Main Summary Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DuoColors.lavenderSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: DuoColors.lavenderBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedDateRange != null ? 'Filtered Spending' : 'Total Spent This Month',
                              style: const TextStyle(fontSize: 12, color: DuoColors.textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DuoFormatters.formatCurrency(totalSpent),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: DuoColors.primary,
                              ),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            side: const BorderSide(color: DuoColors.lavenderBorder),
                          ),
                          icon: const Icon(Icons.tune_rounded, size: 15, color: DuoColors.primary),
                          label: const Text('Budget', style: TextStyle(fontSize: 12, color: DuoColors.primary)),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BudgetScreen()),
                            );
                            _loadData();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Progress bar
                    if (limit > 0) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
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
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Limit: ${DuoFormatters.formatCurrency(limit)}',
                            style: const TextStyle(fontSize: 11.5, color: DuoColors.textSecondary),
                          ),
                          Text(
                            percentage > 100
                                ? 'Over by ${DuoFormatters.formatCurrency(overSpent)}'
                                : 'Remaining: ${DuoFormatters.formatCurrency(remaining)}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: percentage > 100 ? DuoColors.overBudget : DuoColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      BudgetAlertBadge(
                        alertLevel: _budget?.alertLevel ?? (percentage > 100 ? 'OVER_BUDGET' : (percentage >= 100 ? 'REACHED_100' : (percentage >= 80 ? 'WARNING_80' : 'SAFE'))),
                        percentage: percentage,
                        message: _budget?.alertMessage,
                        isCompact: true,
                      ),
                    ] else ...[
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 14, color: DuoColors.textSecondary),
                          const SizedBox(width: 6),
                          const Text(
                            'No monthly budget set for this period.',
                            style: TextStyle(fontSize: 12, color: DuoColors.textSecondary),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BudgetScreen()),
                              );
                              _loadData();
                            },
                            child: const Text(
                              '+ Set Limit',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DuoColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                onChanged: (val) {
                  _searchQuery = val;
                  _loadData();
                },
                decoration: InputDecoration(
                  hintText: 'Search expenses, merchants, locations...',
                  prefixIcon: const Icon(Icons.search_rounded, color: DuoColors.primary, size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchQuery = '';
                            _loadData();
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(cat),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : DuoColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      backgroundColor: Colors.white,
                      selectedColor: DuoColors.primary,
                      side: BorderSide(
                        color: isSelected ? DuoColors.primary : DuoColors.lavenderBorder,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (_) {
                        setState(() => _selectedCategory = cat);
                        _loadData();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            // Expenses List / States
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: DuoColors.primary),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cloud_off_rounded, size: 48, color: DuoColors.textSecondary),
                                const SizedBox(height: 12),
                                Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: DuoColors.textSecondary)),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _loadData,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Try Again'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _expenses.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.receipt_long_outlined, size: 54, color: DuoColors.lavenderBorder),
                                  const SizedBox(height: 12),
                                  Text(
                                    selectedCategory != 'All' || searchQuery.isNotEmpty || _selectedDateRange != null
                                        ? 'No matching expenses found.'
                                        : 'No expenses recorded for this month.',
                                    style: const TextStyle(color: DuoColors.textSecondary),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: DuoColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Add Expense'),
                                    onPressed: () async {
                                      final added = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                                      );
                                      if (added == true) _loadData();
                                    },
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _expenses.length,
                              itemBuilder: (context, index) {
                                final item = _expenses[index];
                                final catColor = DuoFormatters.colorForCategory(item.category);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    onTap: () async {
                                      // Edit Expense
                                      final updated = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddExpenseScreen(expenseToEdit: item),
                                        ),
                                      );
                                      if (updated == true) _loadData();
                                    },
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    leading: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: catColor.withValues(alpha: 0.14),
                                      child: Icon(
                                        DuoFormatters.iconForCategory(item.category),
                                        color: catColor,
                                        size: 22,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (item.receipt != null && item.receipt!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 6),
                                            child: Tooltip(
                                              message: 'Receipt Attached',
                                              child: Container(
                                                padding: const EdgeInsets.all(3),
                                                decoration: BoxDecoration(
                                                  color: DuoColors.mintAccent.withValues(alpha: 0.4),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Icon(Icons.attachment_rounded, size: 13, color: DuoColors.success),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item.category} • ${DuoFormatters.formatDate(item.expenseDate)}',
                                          style: const TextStyle(fontSize: 12, color: DuoColors.textSecondary),
                                        ),
                                        if (item.location.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.place_outlined, size: 12, color: DuoColors.textMuted),
                                              const SizedBox(width: 3),
                                              Expanded(
                                                child: Text(
                                                  item.location,
                                                  style: const TextStyle(fontSize: 11, color: DuoColors.textMuted),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '- ${DuoFormatters.formatCurrency(item.amount)}',
                                              style: const TextStyle(
                                                color: DuoColors.overBudget,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.5,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: DuoColors.lavenderSurface,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                item.paymentMethod,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: DuoColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 19, color: DuoColors.textMuted),
                                          tooltip: 'Delete',
                                          onPressed: () => _deleteExpense(item),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }
}
