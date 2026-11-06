class ApiConstants {
  // Override at compile-time via --dart-define=API_URL=https://your-domain.com/api
  // Default is local development URL
  static String _customBaseUrl = const String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  static String get baseUrl => _customBaseUrl;

  static void setBaseUrl(String url) {
    if (url.endsWith('/')) {
      _customBaseUrl = url.substring(0, url.length - 1);
    } else {
      _customBaseUrl = url;
    }
  }

  // Auth / Account endpoints
  static String get register => '$baseUrl/accounts/register/';
  static String get login => '$baseUrl/accounts/login/';
  static String get logout => '$baseUrl/accounts/logout/';
  static String get forgotPassword => '$baseUrl/accounts/forgot-password/';
  static String get resetPassword => '$baseUrl/accounts/reset-password/';
  static String get refreshToken => '$baseUrl/accounts/token/refresh/';
  static String get profile => '$baseUrl/accounts/profile/';
  static String get dashboard => '$baseUrl/accounts/dashboard/';

  // Task endpoints
  static String get tasks => '$baseUrl/tasks/';
  static String get taskSummary => '$baseUrl/tasks/summary/';
  static String taskDetail(int id) => '$baseUrl/tasks/$id/';
  static String toggleTask(int id) => '$baseUrl/tasks/$id/toggle/';

  // Expense endpoints
  static String get expenses => '$baseUrl/expenses/';
  static String get expenseSummary => '$baseUrl/expenses/summary/';
  static String expenseDetail(int id) => '$baseUrl/expenses/$id/';

  // Budget endpoints
  static String get budgets => '$baseUrl/budgets/';
  static String get currentBudget => '$baseUrl/budgets/current/';
  static String budgetDetail(int id) => '$baseUrl/budgets/$id/';
}
