import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../models/budget_model.dart';
import 'api_service.dart';

class BudgetService {
  static Future<BudgetModel> getCurrentBudget({int? month, int? year}) async {
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;

    try {
      final res = await ApiService.get('${ApiConstants.currentBudget}?month=$m&year=$y');
      if (res.success && res.data is Map) {
        return BudgetModel.fromJson(res.data as Map);
      }
    } catch (e) {
      debugPrint('BudgetService.getCurrentBudget error: $e');
    }

    return BudgetModel.empty(month: m, year: y);
  }

  static Future<ApiResponse> setBudget({
    required int month,
    required int year,
    required double amountLimit,
  }) async {
    final payload = {
      'month': month,
      'year': year,
      'amount_limit': amountLimit.toStringAsFixed(2),
    };

    return await ApiService.post(ApiConstants.currentBudget, payload);
  }

  static Future<List<BudgetModel>> getBudgets() async {
    try {
      final res = await ApiService.get(ApiConstants.budgets);
      if (res.success && res.data is List) {
        return (res.data as List)
            .map((b) => BudgetModel.fromJson(b as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('BudgetService.getBudgets error: $e');
    }
    return [];
  }
}

