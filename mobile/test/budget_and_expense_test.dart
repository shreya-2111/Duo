import 'package:flutter_test/flutter_test.dart';
import 'package:duo/core/models/budget_model.dart';
import 'package:duo/core/models/expense_model.dart';

void main() {
  group('BudgetModel Calculation Tests', () {
    test('Correctly calculates safe budget utilization (<80%)', () {
      final json = {
        'id': 1,
        'month': 11,
        'year': 2026,
        'amount_limit': '10000.00',
        'summary': {
          'budget_id': 1,
          'month': 11,
          'year': 2026,
          'amount_limit': 10000.0,
          'total_spent': 5000.0,
          'remaining': 5000.0,
          'over_spent': 0.0,
          'percentage_used': 50.0,
          'alert_level': 'SAFE',
          'alert_message': 'On track: 50.0% used.',
        }
      };

      final budget = BudgetModel.fromJson(json);
      expect(budget.id, 1);
      expect(budget.amountLimit, 10000.0);
      expect(budget.totalSpent, 5000.0);
      expect(budget.remaining, 5000.0);
      expect(budget.overSpent, 0.0);
      expect(budget.percentageUsed, 50.0);
      expect(budget.alertLevel, 'SAFE');
      expect(budget.isConfigured, true);
    });

    test('Correctly calculates warning budget utilization (>=80% and <100%)', () {
      final json = {
        'id': 2,
        'month': 11,
        'year': 2026,
        'amount_limit': '20000.00',
        'summary': {
          'budget_id': 2,
          'month': 11,
          'year': 2026,
          'amount_limit': 20000.0,
          'total_spent': 17000.0,
          'remaining': 3000.0,
          'over_spent': 0.0,
          'percentage_used': 85.0,
          'alert_level': 'WARNING_80',
          'alert_message': 'Budget Alert: You have used 85.0% of your monthly allowance.',
        }
      };

      final budget = BudgetModel.fromJson(json);
      expect(budget.percentageUsed, 85.0);
      expect(budget.alertLevel, 'WARNING_80');
      expect(budget.remaining, 3000.0);
    });

    test('Correctly handles exact 100% budget reached', () {
      final json = {
        'id': 3,
        'month': 11,
        'year': 2026,
        'amount_limit': '15000.00',
        'summary': {
          'budget_id': 3,
          'month': 11,
          'year': 2026,
          'amount_limit': 15000.0,
          'total_spent': 15000.0,
          'remaining': 0.0,
          'over_spent': 0.0,
          'percentage_used': 100.0,
          'alert_level': 'REACHED_100',
          'alert_message': '100% of your monthly budget reached!',
        }
      };

      final budget = BudgetModel.fromJson(json);
      expect(budget.percentageUsed, 100.0);
      expect(budget.alertLevel, 'REACHED_100');
      expect(budget.remaining, 0.0);
      expect(budget.overSpent, 0.0);
    });

    test('Correctly calculates over-budget status (>100%) without blocking', () {
      final json = {
        'id': 4,
        'month': 11,
        'year': 2026,
        'amount_limit': '10000.00',
        'summary': {
          'budget_id': 4,
          'month': 11,
          'year': 2026,
          'amount_limit': 10000.0,
          'total_spent': 13500.0,
          'remaining': 0.0,
          'over_spent': 3500.0,
          'percentage_used': 135.0,
          'alert_level': 'OVER_BUDGET',
          'alert_message': 'Budget exceeded by ₹3500.00!',
        }
      };

      final budget = BudgetModel.fromJson(json);
      expect(budget.percentageUsed, 135.0);
      expect(budget.alertLevel, 'OVER_BUDGET');
      expect(budget.overSpent, 3500.0);
      expect(budget.remaining, 0.0);
    });
  });

  group('ExpenseModel & Summary Tests', () {
    test('Parses ExpenseModel from DRF JSON accurately', () {
      final json = {
        'id': 42,
        'title': 'Dinner at Toit',
        'amount': '1850.50',
        'category': 'Food',
        'description': 'Craft brew and pizza',
        'location': 'Indiranagar',
        'payment_method': 'UPI',
        'expense_date': '2026-11-04',
        'receipt': '/media/receipts/2026/11/toit.jpg',
        'owner_name': 'Sumit',
        'created_at': '2026-11-04T20:30:00Z',
      };

      final exp = ExpenseModel.fromJson(json);
      expect(exp.id, 42);
      expect(exp.title, 'Dinner at Toit');
      expect(exp.amount, 1850.50);
      expect(exp.category, 'Food');
      expect(exp.paymentMethod, 'UPI');
      expect(exp.location, 'Indiranagar');
      expect(exp.expenseDate.year, 2026);
      expect(exp.expenseDate.month, 11);
      expect(exp.expenseDate.day, 4);
      expect(exp.receipt, '/media/receipts/2026/11/toit.jpg');
    });

    test('Parses MonthlySummaryModel with comparison and category breakdown', () {
      final summaryJson = {
        'year': 2026,
        'month': 11,
        'currency': 'INR',
        'symbol': '₹',
        'total_spent': 8500.0,
        'transaction_count': 5,
        'daily_average': 283.33,
        'monthly_comparison': {
          'previous_month': 10,
          'previous_year': 2026,
          'previous_spent': 7000.0,
          'difference': 1500.0,
          'change_percentage': 21.4,
          'trend': 'UP',
        },
        'categories': [
          {'category': 'Food', 'total': 5000.0, 'count': 3, 'percentage': 58.8},
          {'category': 'Bills', 'total': 3500.0, 'count': 2, 'percentage': 41.2},
        ],
      };

      final summary = MonthlySummaryModel.fromJson(summaryJson);
      expect(summary.totalSpent, 8500.0);
      expect(summary.transactionCount, 5);
      expect(summary.categories.length, 2);
      expect(summary.categories[0].category, 'Food');
      expect(summary.categories[0].total, 5000.0);
      expect(summary.comparison?.trend, 'UP');
      expect(summary.comparison?.difference, 1500.0);
    });
  });
}

