import 'package:flutter/material.dart';

class ExpenseItem {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String description;
  final String location;
  final String paymentMethod;

  ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.description = '',
    this.location = '',
    this.paymentMethod = 'UPI',
  });
}

class TaskItem {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String priority; // 'High', 'Medium', 'Low'
  final bool isShared;
  final String? assigneeName; // 'You', 'Shreya', etc.
  final bool isAssignedToMe;
  bool isDone;

  TaskItem({
    required this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.priority = 'Medium',
    this.isShared = false,
    this.assigneeName,
    this.isAssignedToMe = true,
    this.isDone = false,
  });
}

class DuoMockData extends ChangeNotifier {
  static final DuoMockData _instance = DuoMockData._internal();
  factory DuoMockData() => _instance;
  DuoMockData._internal();

  // User Profile
  String userName = 'Alex Sharma';
  String userEmail = 'alex.sharma@duo.app';
  String myInviteCode = 'DUO-9X7K2P';
  bool isPartnerConnected = true;
  String? partnerName = 'Shreya Raval';
  String? partnerEmail = 'shreya.raval@duo.app';
  String? partnerCode = 'DUO-4K8P1X';

  // Budget Data
  double monthlyBudgetLimit = 35000.0;

  // Expenses Mock Data
  final List<ExpenseItem> _expenses = [
    ExpenseItem(
      id: 'exp_1',
      title: 'Whole Foods Grocery',
      amount: 3450.0,
      category: 'Food',
      date: DateTime.now().subtract(const Duration(hours: 3)),
      description: 'Weekly organic pantry & farm vegetables',
      location: 'Blinkit, Indiranagar',
      paymentMethod: 'UPI',
    ),
    ExpenseItem(
      id: 'exp_2',
      title: 'Electricity & WiFi Bill',
      amount: 2890.0,
      category: 'Bills',
      date: DateTime.now().subtract(const Duration(days: 1)),
      description: 'Bescom power and Airtel 300Mbps fiber combo',
      location: 'Airtel Thanks App',
      paymentMethod: 'Net Banking',
    ),
    ExpenseItem(
      id: 'exp_3',
      title: 'Zara Autumn Blazer',
      amount: 4990.0,
      category: 'Shopping',
      date: DateTime.now().subtract(const Duration(days: 2)),
      description: 'Premium tailored jacket for conference',
      location: 'Phoenix Marketcity',
      paymentMethod: 'Credit Card',
    ),
    ExpenseItem(
      id: 'exp_4',
      title: 'Metro Commute Recharge',
      amount: 800.0,
      category: 'Travel',
      date: DateTime.now().subtract(const Duration(days: 3)),
      description: 'Namma Metro monthly travel pass top-up',
      location: 'MG Road Station',
      paymentMethod: 'UPI',
    ),
    ExpenseItem(
      id: 'exp_5',
      title: 'Dental Health Checkup',
      amount: 1200.0,
      category: 'Health',
      date: DateTime.now().subtract(const Duration(days: 4)),
      description: 'Annual dental prophylaxis and scaling',
      location: 'Apollo Clinic',
      paymentMethod: 'Debit Card',
    ),
    ExpenseItem(
      id: 'exp_6',
      title: 'Netflix & Spotify Family',
      amount: 949.0,
      category: 'Entertainment',
      date: DateTime.now().subtract(const Duration(days: 5)),
      description: 'Monthly 4K streaming and music subscription',
      location: 'Auto-debit',
      paymentMethod: 'Credit Card',
    ),
    ExpenseItem(
      id: 'exp_7',
      title: 'Blue Tokai Roastery',
      amount: 520.0,
      category: 'Food',
      date: DateTime.now().subtract(const Duration(days: 6)),
      description: 'Cold brew and sourdough toast with team',
      location: 'Blue Tokai, Koramangala',
      paymentMethod: 'UPI',
    ),
  ];

  // Personal Tasks Mock Data
  final List<TaskItem> _personalTasks = [
    TaskItem(
      id: 'pt_1',
      title: 'File Q3 Investment Declarations',
      description: 'Collate mutual fund ELSS receipts and submit on portal',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      priority: 'High',
      isShared: false,
      isDone: false,
    ),
    TaskItem(
      id: 'pt_2',
      title: 'Order Monthly Vitamin Supplements',
      description: 'B-Complex and Omega-3 capsules from Tata 1mg',
      dueDate: DateTime.now().add(const Duration(days: 3)),
      priority: 'Medium',
      isShared: false,
      isDone: false,
    ),
    TaskItem(
      id: 'pt_3',
      title: 'Book Periodic Car Service',
      description: '40,000 km oil change and brake pad checkup',
      dueDate: DateTime.now().add(const Duration(days: 5)),
      priority: 'Low',
      isShared: false,
      isDone: false,
    ),
    TaskItem(
      id: 'pt_4',
      title: 'Pick up Dry Cleaned Suits',
      description: 'Collect grey blazer and trousers for Friday meetup',
      dueDate: DateTime.now(),
      priority: 'Medium',
      isShared: false,
      isDone: true,
    ),
  ];

  // Shared Tasks Mock Data
  final List<TaskItem> _sharedTasks = [
    TaskItem(
      id: 'st_1',
      title: 'Compare & Book Holiday Flights',
      description: 'Check Indigo vs Vistara for Delhi trip over Diwali',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      priority: 'High',
      isShared: true,
      assigneeName: 'Shreya',
      isAssignedToMe: false,
      isDone: false,
    ),
    TaskItem(
      id: 'st_2',
      title: 'Plan Sunday Brunch Grocery List',
      description: 'Avocados, sourdough loaf, berries and oat milk',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      priority: 'Medium',
      isShared: true,
      assigneeName: 'You',
      isAssignedToMe: true,
      isDone: false,
    ),
    TaskItem(
      id: 'st_3',
      title: 'Review New Apartment Agreement',
      description: 'Verify maintenance clause and refundable deposit terms',
      dueDate: DateTime.now().add(const Duration(days: 4)),
      priority: 'High',
      isShared: true,
      assigneeName: 'You',
      isAssignedToMe: true,
      isDone: false,
    ),
    TaskItem(
      id: 'st_4',
      title: 'Mom Birthday Gift Selection',
      description: 'Handcrafted Kashmiri pashmina stole or jewelry box',
      dueDate: DateTime.now().add(const Duration(days: 7)),
      priority: 'Medium',
      isShared: true,
      assigneeName: 'Shreya',
      isAssignedToMe: false,
      isDone: true,
    ),
  ];

  // Getters
  List<ExpenseItem> get expenses => List.unmodifiable(_expenses);
  List<TaskItem> get personalTasks => List.unmodifiable(_personalTasks);
  List<TaskItem> get sharedTasks => List.unmodifiable(_sharedTasks);

  double get totalSpent => _expenses.fold(0.0, (sum, e) => sum + e.amount);
  double get remainingBudget => (monthlyBudgetLimit - totalSpent).clamp(0.0, double.infinity);
  double get budgetPercentage => monthlyBudgetLimit > 0 ? (totalSpent / monthlyBudgetLimit * 100) : 0.0;

  String get budgetAlertLevel {
    final p = budgetPercentage;
    if (p > 100) return 'OVER_BUDGET';
    if (p == 100) return 'REACHED_100';
    if (p >= 80) return 'WARNING_80';
    return 'SAFE';
  }

  String get budgetAlertMessage {
    final p = budgetPercentage;
    if (p > 100) {
      final over = totalSpent - monthlyBudgetLimit;
      return 'You are over your monthly budget by ₹${over.toStringAsFixed(0)}!';
    } else if (p == 100) {
      return 'You have reached 100% of your monthly budget limit.';
    } else if (p >= 80) {
      return 'Heads up! You have spent ${p.toStringAsFixed(1)}% of your monthly budget.';
    }
    return 'Great job! You are well within your monthly budget.';
  }

  // Actions
  void addExpense(ExpenseItem item) {
    _expenses.insert(0, item);
    notifyListeners();
  }

  void deleteExpense(String id) {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void togglePersonalTask(String id) {
    final task = _personalTasks.firstWhere((t) => t.id == id);
    task.isDone = !task.isDone;
    notifyListeners();
  }

  void addPersonalTask(TaskItem item) {
    _personalTasks.insert(0, item);
    notifyListeners();
  }

  void deletePersonalTask(String id) {
    _personalTasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void toggleSharedTask(String id) {
    final task = _sharedTasks.firstWhere((t) => t.id == id);
    task.isDone = !task.isDone;
    notifyListeners();
  }

  void addSharedTask(TaskItem item) {
    _sharedTasks.insert(0, item);
    notifyListeners();
  }

  void deleteSharedTask(String id) {
    _sharedTasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void updateBudgetLimit(double newLimit) {
    monthlyBudgetLimit = newLimit;
    notifyListeners();
  }

  bool connectPartner(String code) {
    if (code.trim().toUpperCase() == myInviteCode) return false;
    isPartnerConnected = true;
    partnerName = 'Shreya Raval';
    partnerEmail = 'shreya.raval@duo.app';
    partnerCode = code.trim().toUpperCase();
    notifyListeners();
    return true;
  }

  void disconnectPartner() {
    isPartnerConnected = false;
    partnerName = null;
    partnerEmail = null;
    partnerCode = null;
    notifyListeners();
  }
}

