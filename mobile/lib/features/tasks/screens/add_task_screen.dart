import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/task_model.dart';
import '../../../core/network/task_service.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/duo_button.dart';

class AddTaskScreen extends StatefulWidget {
  final TaskModel? taskToEdit;
  final DateTime? initialDueDate;

  const AddTaskScreen({
    super.key,
    this.taskToEdit,
    this.initialDueDate,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _priority = 'MEDIUM'; // 'HIGH', 'MEDIUM', 'LOW'
  String _status = 'PENDING';   // 'PENDING', 'IN_PROGRESS', 'COMPLETED'
  String _category = 'General';
  String _repeatType = 'NONE';  // 'NONE', 'DAILY', 'WEEKLY', 'MONTHLY'

  DateTime _dueDate = DateTime.now();
  TimeOfDay? _dueTime;

  bool _hasReminder = false;
  TimeOfDay? _reminderTime;

  bool _isSaving = false;
  bool _isDeleting = false;

  final List<String> _categories = [
    'General',
    'Work',
    'Home',
    'Health',
    'Finance',
    'Errands',
    'Personal',
  ];

  final List<String> _priorities = ['HIGH', 'MEDIUM', 'LOW'];
  final List<String> _statuses = ['PENDING', 'IN_PROGRESS', 'COMPLETED'];
  final List<String> _repeatTypes = ['NONE', 'DAILY', 'WEEKLY', 'MONTHLY'];

  @override
  void initState() {
    super.initState();
    if (widget.initialDueDate != null) {
      _dueDate = widget.initialDueDate!;
    }
    _initFromTask();
  }

  void _initFromTask() {
    if (widget.taskToEdit != null) {
      final t = widget.taskToEdit!;
      _titleController.text = t.title;
      _descController.text = t.description;
      _priority = _priorities.contains(t.priority.toUpperCase()) ? t.priority.toUpperCase() : 'MEDIUM';
      _status = _statuses.contains(t.status.toUpperCase()) ? t.status.toUpperCase() : 'PENDING';
      _category = _categories.contains(t.category) ? t.category : 'General';
      _repeatType = _repeatTypes.contains(t.repeatType.toUpperCase()) ? t.repeatType.toUpperCase() : 'NONE';
      _hasReminder = t.hasReminder;

      if (t.dueDate != null) {
        _dueDate = DateTime.tryParse(t.dueDate!) ?? DateTime.now();
      }
      if (t.dueTime != null && t.dueTime!.isNotEmpty) {
        final parts = t.dueTime!.split(':');
        if (parts.length >= 2) {
          _dueTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
      if (t.reminderTime != null && t.reminderTime!.isNotEmpty) {
        final parts = t.reminderTime!.split(':');
        if (parts.length >= 2) {
          _reminderTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
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
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickDueTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? const TimeOfDay(hour: 18, minute: 0),
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
      setState(() => _dueTime = picked);
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
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
      setState(() {
        _reminderTime = picked;
        _hasReminder = true;
      });
    }
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final token = await AuthStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('⚠️ You are not logged in. Please sign in to save tasks.'),
          backgroundColor: DuoColors.overBudget,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dueDateStr = DuoFormatters.apiDate(_dueDate);
      String? dueTimeStr;
      if (_dueTime != null) {
        final h = _dueTime!.hour.toString().padLeft(2, '0');
        final m = _dueTime!.minute.toString().padLeft(2, '0');
        dueTimeStr = '$h:$m:00';
      }

      String? reminderTimeStr;
      if (_hasReminder && _reminderTime != null) {
        final h = _reminderTime!.hour.toString().padLeft(2, '0');
        final m = _reminderTime!.minute.toString().padLeft(2, '0');
        reminderTimeStr = '$h:$m:00';
      }

      final payload = <String, dynamic>{
        'title': title,
        'description': _descController.text.trim(),
        'category': _category,
        'priority': _priority,
        'status': _status,
        'due_date': dueDateStr,
        'repeat_type': _repeatType,
        'has_reminder': _hasReminder,
      };

      if (dueTimeStr != null) {
        payload['due_time'] = dueTimeStr;
      }
      if (reminderTimeStr != null) {
        payload['reminder_time'] = reminderTimeStr;
      }

      if (widget.taskToEdit != null) {
        final res = await TaskService.updateTask(widget.taskToEdit!.id, payload);
        if (res.success) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('✅ Task updated successfully!'),
              backgroundColor: DuoColors.success,
            ),
          );
          if (mounted) Navigator.pop(context, true);
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(res.errorMessage ?? 'Failed to update task.'),
              backgroundColor: DuoColors.overBudget,
            ),
          );
        }
      } else {
        final res = await TaskService.createTask(payload);
        if (res.success) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('✅ Task created successfully!'),
              backgroundColor: DuoColors.success,
            ),
          );
          if (mounted) Navigator.pop(context, true);
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(res.errorMessage ?? 'Failed to create task.'),
              backgroundColor: DuoColors.overBudget,
            ),
          );
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: DuoColors.overBudget,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete() async {
    if (widget.taskToEdit == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to permanently delete this task?'),
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

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      final res = await TaskService.deleteTask(widget.taskToEdit!.id);
      if (res.success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Task deleted successfully.'),
            backgroundColor: DuoColors.primary,
          ),
        );
        if (mounted) navigator.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(res.errorMessage ?? 'Failed to delete task.'),
            backgroundColor: DuoColors.overBudget,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: DuoColors.overBudget),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  bool get _hasUnsavedChanges {
    if (widget.taskToEdit != null) {
      final t = widget.taskToEdit!;
      return _titleController.text.trim() != t.title ||
          _descController.text.trim() != t.description ||
          _priority != t.priority ||
          _status != t.status ||
          _category != t.category ||
          _repeatType != t.repeatType ||
          _hasReminder != t.hasReminder;
    }
    return _titleController.text.trim().isNotEmpty ||
        _descController.text.trim().isNotEmpty;
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
    final isEdit = widget.taskToEdit != null;

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
          title: Text(isEdit ? 'Edit Task' : 'Add Task'),
          actions: [
            if (isEdit)
              IconButton(
                icon: _isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: DuoColors.overBudget),
                      )
                    : const Icon(Icons.delete_outline, color: DuoColors.overBudget),
                tooltip: 'Delete Task',
                onPressed: _isDeleting ? null : _handleDelete,
              ),
          ],
        ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DuoColors.lavenderBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text('Task Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Pay electricity bill, File tax returns',
                  prefixIcon: Icon(Icons.check_box_outlined, color: DuoColors.primary),
                ),
              ),
              const SizedBox(height: 18),

              // Description
              const Text('Description (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              const SizedBox(height: 6),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add details, notes, links or checklist items...',
                ),
              ),
              const SizedBox(height: 18),

              // Category & Priority Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: DuoColors.lavenderSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: DuoColors.lavenderBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _category,
                              items: _categories.map((c) {
                                return DropdownMenuItem(
                                  value: c,
                                  child: Text(c, style: const TextStyle(fontSize: 13.5)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _category = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: DuoColors.lavenderSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: DuoColors.lavenderBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _priority,
                              items: const [
                                DropdownMenuItem(value: 'HIGH', child: Text('🔴 High', style: TextStyle(fontSize: 13.5))),
                                DropdownMenuItem(value: 'MEDIUM', child: Text('🟡 Medium', style: TextStyle(fontSize: 13.5))),
                                DropdownMenuItem(value: 'LOW', child: Text('🟢 Low', style: TextStyle(fontSize: 13.5))),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _priority = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Status (for editing) & Repeat Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: DuoColors.lavenderSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: DuoColors.lavenderBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _status,
                              items: const [
                                DropdownMenuItem(value: 'PENDING', child: Text('Pending', style: TextStyle(fontSize: 13.5))),
                                DropdownMenuItem(value: 'IN_PROGRESS', child: Text('In Progress', style: TextStyle(fontSize: 13.5))),
                                DropdownMenuItem(value: 'COMPLETED', child: Text('Completed', style: TextStyle(fontSize: 13.5))),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _status = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Repeat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: DuoColors.lavenderSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: DuoColors.lavenderBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _repeatType,
                              items: const [
                                DropdownMenuItem(value: 'NONE', child: Text('Does Not Repeat', style: TextStyle(fontSize: 13.5))),
                                DropdownMenuItem(value: 'DAILY', child: Text('Daily', style: TextStyle(fontSize: 13.5))),
                                DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly', style: TextStyle(fontSize: 13.5))),
                                DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly', style: TextStyle(fontSize: 13.5))),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _repeatType = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Due Date & Due Time
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickDueDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                            decoration: BoxDecoration(
                              color: DuoColors.lavenderSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: DuoColors.lavenderBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: DuoColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  DuoFormatters.formatDate(_dueDate),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Due Time (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickDueTime,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                            decoration: BoxDecoration(
                              color: DuoColors.lavenderSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: DuoColors.lavenderBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 16, color: DuoColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  _dueTime != null ? _dueTime!.format(context) : 'Set Time',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _dueTime != null ? DuoColors.textPrimary : DuoColors.textMuted,
                                  ),
                                ),
                                if (_dueTime != null) ...[
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => setState(() => _dueTime = null),
                                    child: const Icon(Icons.close, size: 16, color: DuoColors.textMuted),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Personal Reminder Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DuoColors.lavenderSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DuoColors.lavenderBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, color: DuoColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Personal Reminder', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(
                            _hasReminder && _reminderTime != null
                                ? 'Alert at ${_reminderTime!.format(context)}'
                                : 'Get notified before task is due',
                            style: const TextStyle(fontSize: 11, color: DuoColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (_hasReminder)
                      TextButton(
                        onPressed: _pickReminderTime,
                        child: const Text('Change Time', style: TextStyle(fontSize: 11.5, color: DuoColors.primary)),
                      ),
                    Switch(
                      value: _hasReminder,
                      activeThumbColor: DuoColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _hasReminder = val;
                          if (val && _reminderTime == null) {
                            _reminderTime = const TimeOfDay(hour: 9, minute: 0);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              DuoButton(
                title: isEdit ? 'Update Task' : 'Save Task',
                isLoading: _isSaving,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
