class BudgetModel {
  final int? id;
  final int month;
  final int year;
  final double amountLimit;
  final double totalSpent;
  final double remaining;
  final double overSpent;
  final double percentageUsed;
  final String alertLevel;
  final String alertMessage;
  final bool isConfigured;

  BudgetModel({
    this.id,
    required this.month,
    required this.year,
    required this.amountLimit,
    required this.totalSpent,
    required this.remaining,
    required this.overSpent,
    required this.percentageUsed,
    required this.alertLevel,
    required this.alertMessage,
    required this.isConfigured,
  });

  factory BudgetModel.fromJson(Map<dynamic, dynamic> json) {
    // If backend returns wrapper { "configured": ..., "budget": { ... } } or { "summary": { ... } }
    Map<dynamic, dynamic> summary = {};
    int? budgetId;
    double limit = 0.0;
    int m = DateTime.now().month;
    int y = DateTime.now().year;
    bool configured = true;

    if (json.containsKey('configured')) {
      configured = json['configured'] == true;
    }

    if (json.containsKey('budget') && json['budget'] is Map) {
      final b = json['budget'] as Map;
      budgetId = b['id'] is int ? b['id'] as int : int.tryParse(b['id']?.toString() ?? '');
      m = b['month'] is int ? b['month'] as int : (int.tryParse(b['month']?.toString() ?? '') ?? m);
      y = b['year'] is int ? b['year'] as int : (int.tryParse(b['year']?.toString() ?? '') ?? y);
      limit = double.tryParse(b['amount_limit']?.toString() ?? '0') ?? 0.0;
      if (b['summary'] is Map) {
        summary = b['summary'] as Map;
      }
    } else if (json.containsKey('summary') && json['summary'] is Map) {
      summary = json['summary'] as Map;
      budgetId = summary['budget_id'] is int ? summary['budget_id'] as int : int.tryParse(summary['budget_id']?.toString() ?? '');
      m = summary['month'] is int ? summary['month'] as int : (int.tryParse(summary['month']?.toString() ?? '') ?? m);
      y = summary['year'] is int ? summary['year'] as int : (int.tryParse(summary['year']?.toString() ?? '') ?? y);
      limit = double.tryParse(summary['amount_limit']?.toString() ?? '0') ?? 0.0;
    } else {
      budgetId = json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '');
      m = json['month'] is int ? json['month'] as int : (int.tryParse(json['month']?.toString() ?? '') ?? m);
      y = json['year'] is int ? json['year'] as int : (int.tryParse(json['year']?.toString() ?? '') ?? y);
      limit = double.tryParse(json['amount_limit']?.toString() ?? '0') ?? 0.0;
      if (json['summary'] is Map) {
        summary = json['summary'] as Map;
      }
    }

    final totalSpent = double.tryParse(summary['total_spent']?.toString() ?? '0') ?? 0.0;
    final remaining = double.tryParse(summary['remaining']?.toString() ?? '0') ??
        (limit > totalSpent ? limit - totalSpent : 0.0);
    final overSpent = double.tryParse(summary['over_spent']?.toString() ?? '0') ??
        (totalSpent > limit ? totalSpent - limit : 0.0);
    final percent = double.tryParse(summary['percentage_used']?.toString() ?? '0') ??
        (limit > 0 ? (totalSpent / limit * 100) : 0.0);
    final alertLevel = summary['alert_level']?.toString() ??
        (limit <= 0 ? 'NO_BUDGET_SET' : (percent > 100 ? 'OVER_BUDGET' : (percent >= 100 ? 'REACHED_100' : (percent >= 80 ? 'WARNING_80' : 'SAFE'))));
    final alertMsg = summary['alert_message']?.toString() ?? '';

    return BudgetModel(
      id: budgetId,
      month: m,
      year: y,
      amountLimit: limit,
      totalSpent: totalSpent,
      remaining: remaining,
      overSpent: overSpent,
      percentageUsed: percent,
      alertLevel: alertLevel,
      alertMessage: alertMsg,
      isConfigured: configured && limit > 0,
    );
  }

  static BudgetModel empty({int? month, int? year}) {
    final now = DateTime.now();
    return BudgetModel(
      id: null,
      month: month ?? now.month,
      year: year ?? now.year,
      amountLimit: 0.0,
      totalSpent: 0.0,
      remaining: 0.0,
      overSpent: 0.0,
      percentageUsed: 0.0,
      alertLevel: 'NO_BUDGET_SET',
      alertMessage: 'No monthly budget configured yet.',
      isConfigured: false,
    );
  }
}

