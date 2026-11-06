import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/task_model.dart';
import '../../../core/network/task_service.dart';
import '../../../core/utils/formatters.dart';
import 'add_task_screen.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  bool _isCalendarView = false;

  String _selectedFilter = 'Pending'; // 'Pending', 'Today', 'In Progress', 'Completed', 'Overdue', 'All'
  String _selectedCategory = 'All';
  String _searchQuery = '';

  DateTime _selectedCalendarDate = DateTime.now();
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  bool _isLoading = true;
  String? _errorMessage;
  List<TaskModel> _tasks = [];

  final List<String> _filterTabs = [
    'Pending',
    'Today',
    'In Progress',
    'Completed',
    'Overdue',
    'All',
  ];

  final List<String> _categories = [
    'All',
    'General',
    'Work',
    'Home',
    'Health',
    'Finance',
    'Errands',
    'Personal',
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? filterArg;
      String? statusArg;
      String? dueDateArg;

      if (_isCalendarView) {
        dueDateArg = DuoFormatters.apiDate(_selectedCalendarDate);
      } else {
        if (_selectedFilter == 'Today') {
          filterArg = 'TODAY';
        } else if (_selectedFilter == 'Overdue') {
          filterArg = 'OVERDUE';
        } else if (_selectedFilter == 'Pending') {
          statusArg = 'PENDING';
        } else if (_selectedFilter == 'In Progress') {
          statusArg = 'IN_PROGRESS';
        } else if (_selectedFilter == 'Completed') {
          statusArg = 'COMPLETED';
        }
      }

      final tasks = await TaskService.getTasks(
        filter: filterArg,
        status: statusArg,
        category: _selectedCategory,
        search: _searchQuery,
        dueDate: dueDateArg,
      );

      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load tasks. Please check your connection.';
        });
      }
    }
  }

  Future<void> _toggleTaskStatus(TaskModel task) async {
    final nextStatus = task.isDone ? 'PENDING' : 'COMPLETED';
    final res = await TaskService.toggleTask(task.id, status: nextStatus);
    if (res.success && mounted) {
      _loadTasks();
    }
  }

  void _previousCalendarMonth() {
    setState(() {
      _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1, 1);
    });
  }

  void _nextCalendarMonth() {
    setState(() {
      _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isCalendarView,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isCalendarView) {
          setState(() => _isCalendarView = false);
        }
      },
      child: Scaffold(
        backgroundColor: DuoColors.background,
        appBar: AppBar(
          leading: _isCalendarView
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back to Tasks List',
                  onPressed: () => setState(() => _isCalendarView = false),
                )
              : null,
          title: Text(_isCalendarView ? 'Calendar View' : 'My Tasks'),
        actions: [
          IconButton(
            icon: Icon(
              _isCalendarView ? Icons.view_agenda_rounded : Icons.calendar_month_rounded,
              color: DuoColors.primary,
            ),
            tooltip: _isCalendarView ? 'Switch to List View' : 'Switch to Calendar View',
            onPressed: () {
              setState(() => _isCalendarView = !_isCalendarView);
              _loadTasks();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: DuoColors.primary, size: 28),
            tooltip: 'Add Task',
            onPressed: () async {
              final added = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTaskScreen(
                    initialDueDate: _isCalendarView ? _selectedCalendarDate : null,
                  ),
                ),
              );
              if (added == true) _loadTasks();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DuoColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_rounded),
        label: Text(_isCalendarView ? 'Add on Selected Date' : 'New Task'),
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AddTaskScreen(
                initialDueDate: _isCalendarView ? _selectedCalendarDate : null,
              ),
            ),
          );
          if (added == true) _loadTasks();
        },
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        color: DuoColors.primary,
        child: Column(
          children: [
            if (_isCalendarView) ...[
              _buildCalendarHeaderAndStrip(),
            ] else ...[
              // Search Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  onChanged: (val) {
                    _searchQuery = val;
                    _loadTasks();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search tasks by title, category...',
                    prefixIcon: const Icon(Icons.search_rounded, color: DuoColors.primary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchQuery = '';
                              _loadTasks();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ),

              // Filter Tabs Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: _filterTabs.map((f) {
                    final isSelected = _selectedFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(f),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : DuoColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12.5,
                        ),
                        backgroundColor: Colors.white,
                        selectedColor: DuoColors.primary,
                        side: BorderSide(
                          color: isSelected ? DuoColors.primary : DuoColors.lavenderBorder,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onSelected: (_) {
                          setState(() => _selectedFilter = f);
                          _loadTasks();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Category Filter Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: _categories.map((c) {
                    final isSelected = _selectedCategory == c;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        selected: isSelected,
                        label: Text(
                          c,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isSelected ? Colors.white : DuoColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        selectedColor: DuoColors.primary.withValues(alpha: 0.85),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onSelected: (_) {
                          setState(() => _selectedCategory = c);
                          _loadTasks();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 6),

            // Tasks List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: DuoColors.primary))
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
                                  onPressed: _loadTasks,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Try Again'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _tasks.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.assignment_turned_in_outlined, size: 54, color: DuoColors.lavenderBorder),
                                  const SizedBox(height: 12),
                                  Text(
                                    _isCalendarView
                                        ? 'No tasks due on ${DuoFormatters.formatDate(_selectedCalendarDate)}.'
                                        : 'No tasks found. Tap + to add one!',
                                    style: const TextStyle(color: DuoColors.textSecondary),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: DuoColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Add Task'),
                                    onPressed: () async {
                                      final added = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddTaskScreen(
                                            initialDueDate: _isCalendarView ? _selectedCalendarDate : null,
                                          ),
                                        ),
                                      );
                                      if (added == true) _loadTasks();
                                    },
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _tasks.length,
                              itemBuilder: (context, index) {
                                final task = _tasks[index];
                                return _buildTaskCard(task);
                              },
                            ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildCalendarHeaderAndStrip() {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthTitle = '${monthNames[_calendarMonth.month - 1]} ${_calendarMonth.year}';
    final daysInMonth = DateUtils.getDaysInMonth(_calendarMonth.year, _calendarMonth.month);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Month Selector Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: DuoColors.primary),
                  onPressed: _previousCalendarMonth,
                ),
                Text(
                  monthTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: DuoColors.primary),
                  onPressed: _nextCalendarMonth,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Horizontal Date Strip
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: daysInMonth,
              itemBuilder: (context, idx) {
                final day = idx + 1;
                final date = DateTime(_calendarMonth.year, _calendarMonth.month, day);
                final isSelected = date.year == _selectedCalendarDate.year &&
                    date.month == _selectedCalendarDate.month &&
                    date.day == _selectedCalendarDate.day;

                const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final weekday = weekdayNames[date.weekday - 1];

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCalendarDate = date);
                    _loadTasks();
                  },
                  child: Container(
                    width: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? DuoColors.primary : DuoColors.lavenderSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? DuoColors.primary : DuoColors.lavenderBorder,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weekday,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white70 : DuoColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : DuoColors.textPrimary,
                          ),
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
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () async {
          final updated = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AddTaskScreen(taskToEdit: task),
            ),
          );
          if (updated == true) _loadTasks();
        },
        leading: IconButton(
          icon: Icon(
            task.isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: task.isDone ? DuoColors.success : DuoColors.textMuted,
            size: 24,
          ),
          onPressed: () => _toggleTaskStatus(task),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            color: task.isDone ? DuoColors.textMuted : DuoColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                task.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: DuoColors.textSecondary),
              ),
            ],
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildPriorityBadge(task.priority),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: DuoColors.lavenderSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task.category,
                    style: const TextStyle(fontSize: 10, color: DuoColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
                if (task.dueDate != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 11,
                        color: task.isOverdue ? DuoColors.overBudget : DuoColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        DuoFormatters.formatShortDate(DateTime.tryParse(task.dueDate!) ?? DateTime.now()),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: task.isOverdue ? FontWeight.bold : FontWeight.normal,
                          color: task.isOverdue ? DuoColors.overBudget : DuoColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                if (task.hasReminder)
                  const Icon(Icons.notifications_active_outlined, size: 12, color: DuoColors.primary),
                if (task.repeatType != 'NONE')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: DuoColors.mintAccent.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task.repeatType,
                      style: const TextStyle(fontSize: 9.5, color: DuoColors.success, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: DuoColors.textMuted),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
