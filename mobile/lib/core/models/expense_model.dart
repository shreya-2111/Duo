import 'budget_model.dart';

class ExpenseModel {
  final int id;
  final String title;
  final double amount;
  final String category;
  final String description;
  final String location;
  final String paymentMethod;
  final DateTime expenseDate;
  final String? receipt;
  final String? ownerName;
  final DateTime? createdAt;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.description,
    required this.location,
    required this.paymentMethod,
    required this.expenseDate,
    this.receipt,
    this.ownerName,
    this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final dateStr = json['expense_date']?.toString() ?? json['date']?.toString();
    if (dateStr != null && dateStr.isNotEmpty) {
      parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    DateTime? created;
    if (json['created_at'] != null) {
      created = DateTime.tryParse(json['created_at'].toString());
    }

    return ExpenseModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      category: json['category']?.toString() ?? 'Other',
      description: json['description']?.toString() ?? json['notes']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? 'UPI',
      expenseDate: parsedDate,
      receipt: json['receipt']?.toString(),
      ownerName: json['owner_name']?.toString(),
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount.toStringAsFixed(2),
      'category': category,
      'description': description,
      'location': location,
      'payment_method': paymentMethod,
      'expense_date': '${expenseDate.year.toString().padLeft(4, '0')}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}',
      'receipt': receipt,
      'owner_name': ownerName,
    };
  }
}

class CategorySpending {
  final String category;
  final double total;
  final int count;
  final double percentage;

  CategorySpending({
    required this.category,
    required this.total,
    required this.count,
    required this.percentage,
  });

  factory CategorySpending.fromJson(Map<String, dynamic> json) {
    return CategorySpending(
      category: json['category']?.toString() ?? 'Other',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      count: json['count'] is int ? json['count'] as int : int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      percentage: double.tryParse(json['percentage']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class MonthlyComparison {
  final int previousMonth;
  final int previousYear;
  final double previousSpent;
  final double difference;
  final double? changePercentage;
  final String trend; // 'UP', 'DOWN', 'SAME'

  MonthlyComparison({
    required this.previousMonth,
    required this.previousYear,
    required this.previousSpent,
    required this.difference,
    this.changePercentage,
    required this.trend,
  });

  factory MonthlyComparison.fromJson(Map<String, dynamic> json) {
    return MonthlyComparison(
      previousMonth: json['previous_month'] is int ? json['previous_month'] as int : 0,
      previousYear: json['previous_year'] is int ? json['previous_year'] as int : 0,
      previousSpent: double.tryParse(json['previous_spent']?.toString() ?? '0') ?? 0.0,
      difference: double.tryParse(json['difference']?.toString() ?? '0') ?? 0.0,
      changePercentage: json['change_percentage'] != null ? double.tryParse(json['change_percentage'].toString()) : null,
      trend: json['trend']?.toString() ?? 'SAME',
    );
  }
}

class MonthlySummaryModel {
  final int year;
  final int month;
  final double totalSpent;
  final int transactionCount;
  final double dailyAverage;
  final List<CategorySpending> categories;
  final MonthlyComparison? comparison;
  final BudgetModel? budget;

  MonthlySummaryModel({
    required this.year,
    required this.month,
    required this.totalSpent,
    required this.transactionCount,
    required this.dailyAverage,
    required this.categories,
    this.comparison,
    this.budget,
  });

  factory MonthlySummaryModel.fromJson(Map<String, dynamic> json) {
    final catList = (json['categories'] as List? ?? [])
        .map((c) => CategorySpending.fromJson(c as Map<String, dynamic>))
        .toList();

    MonthlyComparison? comp;
    if (json['monthly_comparison'] is Map<String, dynamic>) {
      comp = MonthlyComparison.fromJson(json['monthly_comparison'] as Map<String, dynamic>);
    }

    BudgetModel? b;
    if (json['budget'] is Map<String, dynamic>) {
      b = BudgetModel.fromJson(json['budget'] as Map<String, dynamic>);
    }

    return MonthlySummaryModel(
      year: json['year'] is int ? json['year'] as int : DateTime.now().year,
      month: json['month'] is int ? json['month'] as int : DateTime.now().month,
      totalSpent: double.tryParse(json['total_spent']?.toString() ?? '0') ?? 0.0,
      transactionCount: json['transaction_count'] is int ? json['transaction_count'] as int : 0,
      dailyAverage: double.tryParse(json['daily_average']?.toString() ?? '0') ?? 0.0,
      categories: catList,
      comparison: comp,
      budget: b,
    );
  }
}
