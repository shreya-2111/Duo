import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../models/task_model.dart';
import 'api_service.dart';

// Alias for backwards compatibility
typedef SharedTaskModel = TaskModel;

class TaskService {
  static Future<List<TaskModel>> getPersonalTasks({
    String? filter,
    String? status,
    String? category,
    String? search,
    String? dueDate,
    String? startDate,
    String? endDate,
  }) async {
    return await getTasks(
      filter: filter,
      status: status,
      category: category,
      search: search,
      dueDate: dueDate,
      startDate: startDate,
      endDate: endDate,
    );
  }

  static Future<List<TaskModel>> getSharedTasks({
    String? filter,
    String? status,
    String? category,
    String? search,
    bool? assignedToMe,
    bool? assignedToPartner,
  }) async {
    // All tasks are now personal; return empty for shared
    return [];
  }

  static Future<List<TaskModel>> getTasks({
    String? visibility,
    String? filter,
    String? status,
    String? category,
    String? search,
    String? dueDate,
    String? startDate,
    String? endDate,
    bool? assignedToMe,
    bool? assignedToPartner,
  }) async {
    final params = <String>[];
    if (filter != null && filter.isNotEmpty && filter != 'All') {
      params.add('filter=${Uri.encodeComponent(filter)}');
    }
    if (status != null && status.isNotEmpty && status != 'All') {
      params.add('status=${Uri.encodeComponent(status)}');
    }
    if (category != null && category.isNotEmpty && category != 'All') {
      params.add('category=${Uri.encodeComponent(category)}');
    }
    if (search != null && search.trim().isNotEmpty) {
      params.add('search=${Uri.encodeComponent(search.trim())}');
    }
    if (dueDate != null && dueDate.isNotEmpty) {
      params.add('due_date=${Uri.encodeComponent(dueDate)}');
    }
    if (startDate != null && startDate.isNotEmpty) {
      params.add('start_date=${Uri.encodeComponent(startDate)}');
    }
    if (endDate != null && endDate.isNotEmpty) {
      params.add('end_date=${Uri.encodeComponent(endDate)}');
    }

    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final url = '${ApiConstants.tasks}$query';

    try {
      final res = await ApiService.get(url);
      if (res.success && res.data is List) {
        return (res.data as List)
            .map((item) => TaskModel.fromJson(item as Map<dynamic, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('TaskService.getTasks error: $e');
    }
    return [];
  }

  static Future<TaskSummaryCounts> getTaskSummary() async {
    try {
      final res = await ApiService.get(ApiConstants.taskSummary);
      if (res.success && res.data is Map) {
        return TaskSummaryCounts.fromJson(res.data as Map<dynamic, dynamic>);
      }
    } catch (e) {
      debugPrint('TaskService.getTaskSummary error: $e');
    }
    return TaskSummaryCounts.empty();
  }

  static Future<ApiResponse> createTask(Map<String, dynamic> data) async {
    return await ApiService.post(ApiConstants.tasks, data);
  }

  static Future<ApiResponse> updateTask(int id, Map<String, dynamic> data) async {
    return await ApiService.patch(ApiConstants.taskDetail(id), data);
  }

  static Future<ApiResponse> toggleTask(int taskId, {String? status}) async {
    final body = <String, dynamic>{};
    if (status != null) body['status'] = status;
    return await ApiService.patch(ApiConstants.toggleTask(taskId), body);
  }

  static Future<ApiResponse> deleteTask(int taskId) async {
    return await ApiService.delete(ApiConstants.taskDetail(taskId));
  }
}
