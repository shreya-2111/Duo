import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/network/expense_service.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/duo_button.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseModel? expenseToEdit;
  const AddExpenseScreen({super.key, this.expenseToEdit});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String _category = 'Food';
  String _paymentMethod = 'UPI';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _hasReceipt = false;
  String? _receiptFileName;

  final List<String> _categories = [
    'Food',
    'Bills',
    'Shopping',
    'Travel',
    'Health',
    'Entertainment',
    'Other',
  ];

  final List<String> _paymentMethods = [
    'UPI',
    'Credit Card',
    'Debit Card',
    'Cash',
    'Net Banking',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.expenseToEdit != null) {
      final exp = widget.expenseToEdit!;
      _titleController.text = exp.title;
      _amountController.text = exp.amount.toStringAsFixed(2);
      _descriptionController.text = exp.description;
      _locationController.text = exp.location;
      _category = _categories.contains(exp.category) ? exp.category : 'Other';
      _paymentMethod = _paymentMethods.contains(exp.paymentMethod) ? exp.paymentMethod : 'UPI';
      _selectedDate = exp.expenseDate;
      if (exp.receipt != null && exp.receipt!.isNotEmpty) {
        _hasReceipt = true;
        _receiptFileName = exp.receipt!.split('/').last;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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
      setState(() => _selectedDate = picked);
    }
  }

  void _toggleReceipt() {
    setState(() {
      _hasReceipt = !_hasReceipt;
      if (_hasReceipt) {
        _receiptFileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      } else {
        _receiptFileName = null;
      }
    });
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (title.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an expense title and valid amount in ₹.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    final token = await AuthStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('⚠️ You are not logged in. Please sign in to save expenses.'),
          backgroundColor: DuoColors.overBudget,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payload = <String, dynamic>{
        'title': title,
        'amount': amount.toStringAsFixed(2),
        'category': _category,
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'payment_method': _paymentMethod,
        'expense_date': DuoFormatters.apiDate(_selectedDate),
      };

      if (widget.expenseToEdit != null) {
        // Edit existing expense
        final res = await ExpenseService.updateExpense(widget.expenseToEdit!.id, payload);
        if (res.success) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('✅ Expense updated successfully!'),
              backgroundColor: DuoColors.success,
            ),
          );
          if (mounted) Navigator.pop(context, true);
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(res.errorMessage ?? 'Failed to update expense.'),
              backgroundColor: DuoColors.overBudget,
            ),
          );
        }
      } else {
        // Create new expense
        List<int>? fileBytes;
        if (_hasReceipt && _receiptFileName != null) {
          // Minimal 1x1 dummy JPEG header bytes for receipt file upload demonstration
          fileBytes = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0xFF, 0xD9];
        }

        final res = await ExpenseService.createExpense(
          payload,
          fileName: _hasReceipt ? _receiptFileName : null,
          fileBytes: fileBytes,
        );

        if (res.success) {
          // Check backend returned budget_status for threshold alerts
          final budgetStatus = res.data is Map ? res.data['budget_status'] : null;
          if (budgetStatus is Map) {
            final alertLevel = budgetStatus['alert_level']?.toString() ?? '';
            final overSpent = budgetStatus['over_spent'] ?? 0.0;
            final percent = budgetStatus['percentage_used'] ?? 0.0;

            if (alertLevel == 'OVER_BUDGET') {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Expense logged! ⚠️ Over budget by ₹$overSpent (Logging is never blocked).'),
                  backgroundColor: DuoColors.overBudget,
                  duration: const Duration(seconds: 4),
                ),
              );
            } else if (alertLevel == 'REACHED_100') {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Expense logged! ⚠️ 100% of your monthly budget reached.'),
                  backgroundColor: DuoColors.limit100,
                  duration: Duration(seconds: 4),
                ),
              );
            } else if (alertLevel == 'WARNING_80') {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Expense logged! ⚠️ Budget Alert: You have used $percent% of your allowance.'),
                  backgroundColor: DuoColors.warning80,
                  duration: const Duration(seconds: 4),
                ),
              );
            } else {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('✨ Expense added successfully!'),
                  backgroundColor: DuoColors.success,
                ),
              );
            }
          } else {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('✨ Expense added successfully!'),
                backgroundColor: DuoColors.success,
              ),
            );
          }

          if (mounted) Navigator.pop(context, true);
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(res.errorMessage ?? 'Failed to save expense.'),
              backgroundColor: DuoColors.overBudget,
            ),
          );
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: DuoColors.overBudget,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    if (widget.expenseToEdit == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text('Are you sure you want to delete "${widget.expenseToEdit!.title}"?'),
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
      setState(() => _isSaving = true);
      final res = await ExpenseService.deleteExpense(widget.expenseToEdit!.id);
      if (mounted) {
        setState(() => _isSaving = false);
        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense deleted successfully.')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.errorMessage ?? 'Could not delete expense.'),
              backgroundColor: DuoColors.overBudget,
            ),
          );
        }
      }
    }
  }

  bool get _hasUnsavedChanges {
    if (widget.expenseToEdit != null) {
      final exp = widget.expenseToEdit!;
      final currentAmt = double.tryParse(_amountController.text.trim()) ?? 0.0;
      return _titleController.text.trim() != exp.title ||
          (currentAmt - exp.amount).abs() > 0.001 ||
          _descriptionController.text.trim() != exp.description ||
          _locationController.text.trim() != exp.location ||
          _category != exp.category ||
          _paymentMethod != exp.paymentMethod;
    }
    return _titleController.text.trim().isNotEmpty ||
        _amountController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _locationController.text.trim().isNotEmpty;
  }

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
            Text('Discard Changes?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them and go back?',
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
    final isEditing = widget.expenseToEdit != null;

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
            tooltip: 'Back',
            onPressed: () async {
              final discard = await _confirmDiscardChanges();
              if (discard && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
          actions: [
            if (isEditing)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: DuoColors.overBudget),
                tooltip: 'Delete Expense',
                onPressed: _handleDelete,
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Title
                const Text('Expense Title', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Dinner with team',
                    prefixIcon: Icon(Icons.edit_note_rounded, color: DuoColors.primary),
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Amount
                const Text('Amount (INR ₹)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.currency_rupee_rounded, color: DuoColors.primary),
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Category Picker
                const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category_outlined, color: DuoColors.primary),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(
                            DuoFormatters.iconForCategory(cat),
                            size: 18,
                            color: DuoFormatters.colorForCategory(cat),
                          ),
                          const SizedBox(width: 8),
                          Text(cat),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
                const SizedBox(height: 18),

                // 4. Payment Method
                const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.payment_rounded, color: DuoColors.primary),
                  ),
                  items: _paymentMethods.map((pm) {
                    return DropdownMenuItem(
                      value: pm,
                      child: Text(pm),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _paymentMethod = val);
                  },
                ),
                const SizedBox(height: 18),

                // 5. Location
                const Text('Location / Merchant', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Swiggy, Starbucks, Indiranagar',
                    prefixIcon: Icon(Icons.place_outlined, color: DuoColors.primary),
                  ),
                ),
                const SizedBox(height: 18),

                // 6. Date
                const Text('Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: DuoColors.lavenderBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: DuoColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          DuoFormatters.formatDate(_selectedDate),
                          style: const TextStyle(fontSize: 14, color: DuoColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 7. Receipt Attachment
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Receipt Image', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    TextButton.icon(
                      icon: Icon(_hasReceipt ? Icons.check_circle : Icons.attach_file_rounded, size: 16),
                      label: Text(_hasReceipt ? 'Attached' : 'Attach Receipt'),
                      style: TextButton.styleFrom(
                        foregroundColor: _hasReceipt ? DuoColors.success : DuoColors.primary,
                      ),
                      onPressed: _toggleReceipt,
                    ),
                  ],
                ),
                if (_hasReceipt) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: DuoColors.lavenderSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: DuoColors.lavenderBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: DuoColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _receiptFileName ?? 'receipt.jpg',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16, color: DuoColors.overBudget),
                          onPressed: _toggleReceipt,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ] else
                  const SizedBox(height: 6),

                // 8. Description / Notes
                const Text('Description / Notes (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Add extra details for this transaction...',
                  ),
                ),
                const SizedBox(height: 24),

                DuoButton(
                  title: isEditing ? 'Update Expense' : 'Save Expense',
                  isLoading: _isSaving,
                  onPressed: _handleSave,
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
