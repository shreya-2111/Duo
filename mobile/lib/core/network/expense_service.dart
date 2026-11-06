import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../models/expense_model.dart';
import 'api_service.dart';

class ExpenseService {
  static Future<List<ExpenseModel>> getExpenses({
    int? month,
    int? year,
    String? category,
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String>[];
    if (month != null) params.add('month=$month');
    if (year != null) params.add('year=$year');
    if (category != null && category.isNotEmpty && category != 'All') {
      params.add('category=${Uri.encodeComponent(category)}');
    }
    if (search != null && search.trim().isNotEmpty) {
      params.add('search=${Uri.encodeComponent(search.trim())}');
    }
    if (startDate != null && startDate.isNotEmpty) {
      params.add('start_date=${Uri.encodeComponent(startDate)}');
    }
    if (endDate != null && endDate.isNotEmpty) {
      params.add('end_date=${Uri.encodeComponent(endDate)}');
    }

    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final url = '${ApiConstants.expenses}$query';

    try {
      final res = await ApiService.get(url);
      if (res.success && res.data is List) {
        return (res.data as List)
            .map((item) => ExpenseModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('ExpenseService.getExpenses error: $e');
    }
    return [];
  }

  static Future<MonthlySummaryModel?> getMonthlySummary({int? month, int? year}) async {
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;

    try {
      final res = await ApiService.get('${ApiConstants.expenseSummary}?month=$m&year=$y');
      if (res.success && res.data is Map) {
        return MonthlySummaryModel.fromJson(Map<String, dynamic>.from(res.data as Map));
      }
    } catch (e) {
      debugPrint('ExpenseService.getMonthlySummary error: $e');
    }
    return null;
  }

  static Future<ApiResponse> createExpense(
    Map<String, dynamic> data, {
    String? fileName,
    List<int>? fileBytes,
  }) async {
    if (fileName != null && fileBytes != null) {
      final fields = data.map((k, v) => MapEntry(k, v.toString()));
      return await ApiService.postMultipart(
        ApiConstants.expenses,
        fields,
        fileField: 'receipt',
        fileName: fileName,
        fileBytes: fileBytes,
      );
    }

    return await ApiService.post(ApiConstants.expenses, data);
  }

  static Future<ApiResponse> updateExpense(int id, Map<String, dynamic> data) async {
    return await ApiService.patch(ApiConstants.expenseDetail(id), data);
  }

  static Future<ApiResponse> deleteExpense(int id) async {
    return await ApiService.delete(ApiConstants.expenseDetail(id));
  }
}

