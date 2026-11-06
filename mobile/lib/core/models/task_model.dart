class TaskModel {
  final int id;
  final String title;
  final String description;
  final String category;
  final String priority;   // HIGH, MEDIUM, LOW
  final String status;     // PENDING, IN_PROGRESS, COMPLETED
  final bool isDone;
  final bool isOverdue;
  final String? dueDate;
  final String? dueTime;
  final String repeatType; // NONE, DAILY, WEEKLY, MONTHLY
  final bool hasReminder;
  final String? reminderTime;
  final int? creatorId;
  final String? creatorName;
  final String? completedAt;
  final String? createdAt;

  // Backwards compatibility getter
  String get visibility => 'PERSONAL';

  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'General',
    required this.priority,
    required this.status,
    required this.isDone,
    this.isOverdue = false,
    this.dueDate,
    this.dueTime,
    this.repeatType = 'NONE',
    this.hasReminder = false,
    this.reminderTime,
    this.creatorId,
    this.creatorName,
    this.completedAt,
    this.createdAt,
  });

  factory TaskModel.fromJson(Map<dynamic, dynamic> json) {
    final creator = json['creator_details'] is Map ? json['creator_details'] as Map : null;

    final idVal = json['id'] is int
        ? json['id'] as int
        : int.tryParse(json['id']?.toString() ?? '0') ?? 0;

    final priorityStr = (json['priority']?.toString().toUpperCase()) ?? 'MEDIUM';
    final statusStr = (json['status']?.toString().toUpperCase()) ?? 'PENDING';
    final repeatStr = (json['repeat_type']?.toString().toUpperCase()) ?? 'NONE';

    bool overdue = json['is_overdue'] == true;
    if (!overdue && statusStr != 'COMPLETED' && json['due_date'] != null) {
      final parsedDue = DateTime.tryParse(json['due_date'].toString());
      if (parsedDue != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (parsedDue.isBefore(today)) {
          overdue = true;
        }
      }
    }

    return TaskModel(
      id: idVal,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      priority: priorityStr,
      status: statusStr,
      isDone: json['is_done'] == true || statusStr == 'COMPLETED',
      isOverdue: overdue,
      dueDate: json['due_date']?.toString(),
      dueTime: json['due_time']?.toString(),
      repeatType: repeatStr,
      hasReminder: json['has_reminder'] == true,
      reminderTime: json['reminder_time']?.toString(),
      creatorId: creator?['id'] is int ? creator!['id'] as int : int.tryParse(creator?['id']?.toString() ?? ''),
      creatorName: creator?['name']?.toString(),
      completedAt: json['completed_at']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'due_date': dueDate,
      'due_time': dueTime,
      'repeat_type': repeatType,
      'has_reminder': hasReminder,
      if (reminderTime != null) 'reminder_time': reminderTime,
    };
  }
}

class TaskSummaryCounts {
  final int completedTotal;
  final int pendingTotal;
  final int personalPending;
  final int personalInProgress;
  final int personalCompleted;
  final int personalOverdue;
  final int personalToday;

  TaskSummaryCounts({
    required this.completedTotal,
    required this.pendingTotal,
    required this.personalPending,
    required this.personalInProgress,
    required this.personalCompleted,
    required this.personalOverdue,
    required this.personalToday,
  });

  factory TaskSummaryCounts.fromJson(Map<dynamic, dynamic> json) {
    final personal = json['personal'] is Map ? json['personal'] as Map : {};
    final counts = json['counts'] is Map ? json['counts'] as Map : {};

    return TaskSummaryCounts(
      completedTotal: int.tryParse(counts['completed_total']?.toString() ?? json['completed_count']?.toString() ?? '0') ?? 0,
      pendingTotal: int.tryParse(counts['pending_total']?.toString() ?? json['pending_count']?.toString() ?? '0') ?? 0,
      personalPending: int.tryParse(personal['pending']?.toString() ?? '0') ?? 0,
      personalInProgress: int.tryParse(personal['in_progress']?.toString() ?? '0') ?? 0,
      personalCompleted: int.tryParse(personal['completed']?.toString() ?? '0') ?? 0,
      personalOverdue: int.tryParse(personal['overdue']?.toString() ?? '0') ?? 0,
      personalToday: int.tryParse(personal['today']?.toString() ?? '0') ?? 0,
    );
  }

  static TaskSummaryCounts empty() {
    return TaskSummaryCounts(
      completedTotal: 0,
      pendingTotal: 0,
      personalPending: 0,
      personalInProgress: 0,
      personalCompleted: 0,
      personalOverdue: 0,
      personalToday: 0,
    );
  }
}
