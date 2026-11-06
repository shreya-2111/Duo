import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../models/budget_model.dart';
import '../models/expense_model.dart';
import '../models/task_model.dart';
import 'api_service.dart';

class CategoryAnalytics {
  final String category;
  final double total;
  final double percentage;

  CategoryAnalytics({
    required this.category,
    required this.total,
    required this.percentage,
  });

  factory CategoryAnalytics.fromJson(Map<dynamic, dynamic> json) {
    return CategoryAnalytics(
      category: json['category']?.toString() ?? 'Other',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      percentage: double.tryParse(json['percentage']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class DashboardData {
  final Map<String, dynamic>? user;
  final BudgetModel budget;
  final List<ExpenseModel> recentExpenses;
  final List<CategoryAnalytics> spendingAnalytics;
  final List<TaskModel> todayTasks;
  final List<TaskModel> upcomingTasks;
  final List<TaskModel> personalTasks;
  final List<TaskModel> sharedTasks;
  final int completedCount;
  final int pendingCount;
  final Map<String, dynamic> sharedTaskSummary;
  final int unreadNotifications;

  DashboardData({
    this.user,
    required this.budget,
    required this.recentExpenses,
    required this.spendingAnalytics,
    required this.todayTasks,
    required this.upcomingTasks,
    required this.personalTasks,
    required this.sharedTasks,
    required this.completedCount,
    required this.pendingCount,
    required this.sharedTaskSummary,
    required this.unreadNotifications,
  });

  factory DashboardData.fromJson(Map<dynamic, dynamic> json) {
    BudgetModel b = BudgetModel.empty();
    if (json['budget_summary'] is Map) {
      b = BudgetModel.fromJson({'summary': json['budget_summary']});
    }

    final expenses = (json['recent_expenses'] as List? ?? [])
        .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final analytics = (json['spending_analytics'] as List? ?? [])
        .map((c) => CategoryAnalytics.fromJson(c as Map<dynamic, dynamic>))
        .toList();

    final today = (json['today_tasks'] as List? ?? [])
        .map((t) => TaskModel.fromJson(t as Map<dynamic, dynamic>))
        .toList();

    final upcoming = (json['upcoming_tasks'] as List? ?? [])
        .map((t) => TaskModel.fromJson(t as Map<dynamic, dynamic>))
        .toList();

    final personal = (json['personal_tasks'] as List? ?? [])
        .map((t) => TaskModel.fromJson(t as Map<dynamic, dynamic>))
        .toList();

    final shared = (json['shared_tasks'] as List? ?? [])
        .map((t) => TaskModel.fromJson(t as Map<dynamic, dynamic>))
        .toList();

    final stats = json['task_stats'] is Map ? json['task_stats'] as Map : {};
    final compCount = int.tryParse(stats['completed_count']?.toString() ?? '0') ?? 0;
    final pendCount = int.tryParse(stats['pending_count']?.toString() ?? '0') ?? 0;

    final sharedSummary = json['shared_task_summary'] is Map
        ? Map<String, dynamic>.from(json['shared_task_summary'] as Map)
        : <String, dynamic>{};

    final notifCount = json['unread_notifications_count'] is int
        ? json['unread_notifications_count'] as int
        : int.tryParse(json['unread_notifications_count']?.toString() ?? '0') ?? 0;

    return DashboardData(
      user: json['user'] is Map ? Map<String, dynamic>.from(json['user'] as Map) : null,
      budget: b,
      recentExpenses: expenses,
      spendingAnalytics: analytics,
      todayTasks: today,
      upcomingTasks: upcoming,
      personalTasks: personal,
      sharedTasks: shared,
      completedCount: compCount,
      pendingCount: pendCount,
      sharedTaskSummary: sharedSummary,
      unreadNotifications: notifCount,
    );
  }
}

class DashboardService {
  static Future<DashboardData?> getDashboardData() async {
    try {
      final res = await ApiService.get(ApiConstants.dashboard);
      if (res.success && res.data is Map) {
        return DashboardData.fromJson(res.data as Map<dynamic, dynamic>);
      }
    } catch (e) {
      debugPrint('DashboardService.getDashboardData error: $e');
    }
    return null;
  }
}
