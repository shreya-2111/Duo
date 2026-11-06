import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dashboard_service.dart';
import '../../../core/utils/formatters.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  DashboardData? _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await DashboardService.getDashboardData();
      if (mounted) {
        setState(() {
          _data = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load insights. Please check connection.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: DuoColors.background,
        appBar: AppBar(title: const Text('Insights & Analytics')),
        body: const Center(child: CircularProgressIndicator(color: DuoColors.primary)),
      );
    }

    if (_errorMessage != null || _data == null) {
      return Scaffold(
        backgroundColor: DuoColors.background,
        appBar: AppBar(title: const Text('Insights & Analytics')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: DuoColors.textSecondary),
              const SizedBox(height: 12),
              Text(_errorMessage ?? 'Could not load insights.', style: const TextStyle(color: DuoColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final budget = _data!.budget;
    final totalSpent = budget.totalSpent;
    final limit = budget.amountLimit;
    final percentUsed = limit > 0 ? (totalSpent / limit * 100) : 0.0;
    final avgDaily = DateTime.now().day > 0 ? (totalSpent / DateTime.now().day) : totalSpent;

    final analytics = _data!.spendingAnalytics;
    final topCategory = analytics.isNotEmpty ? analytics.first.category : 'None';
    final topCategoryAmount = analytics.isNotEmpty ? analytics.first.total : 0.0;

    final completedTasks = _data!.completedCount;
    final pendingTasks = _data!.pendingCount;
    final totalTasks = completedTasks + pendingTasks;
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0;

    return Scaffold(
      backgroundColor: DuoColors.background,
      appBar: AppBar(
        title: const Text('Insights & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: DuoColors.primary),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: DuoColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Spending Health Score Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [DuoColors.primary, DuoColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: DuoColors.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Monthly Spending Velocity',
                          style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${percentUsed.toStringAsFixed(0)}% Used',
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      DuoFormatters.formatCurrency(totalSpent),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildWhiteStat('Daily Average', DuoFormatters.formatCurrency(avgDaily)),
                        const SizedBox(width: 24),
                        _buildWhiteStat('Top Category', '$topCategory (${DuoFormatters.formatCurrency(topCategoryAmount)})'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Category Spending Visual Distribution
              const Text('Spending by Category', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (analytics.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('No expense categories recorded yet this month.', style: TextStyle(color: DuoColors.textSecondary)),
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: analytics.map((entry) {
                        final cat = entry.category;
                        final total = entry.total;
                        final percent = (entry.percentage / 100).clamp(0.0, 1.0);
                        final color = DuoFormatters.colorForCategory(cat);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: color.withValues(alpha: 0.15),
                                    child: Icon(DuoFormatters.iconForCategory(cat), size: 14, color: color),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(cat, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                  const Spacer(),
                                  Text(
                                    DuoFormatters.formatCurrency(total),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 44,
                                    child: Text(
                                      '${entry.percentage.toStringAsFixed(1)}%',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 11.5, color: DuoColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  minHeight: 7,
                                  backgroundColor: DuoColors.lavenderBorder.withValues(alpha: 0.5),
                                  valueColor: AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // 3. Task Productivity Analytics
              const Text('Task Productivity', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Personal Tasks Completion', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(
                            '${completionRate.toStringAsFixed(0)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: DuoColors.success),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (completionRate / 100).clamp(0.0, 1.0),
                          minHeight: 10,
                          backgroundColor: DuoColors.lavenderBorder.withValues(alpha: 0.5),
                          valueColor: const AlwaysStoppedAnimation<Color>(DuoColors.success),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildTaskStatTile('Completed', '$completedTasks', DuoColors.success),
                          const SizedBox(width: 12),
                          _buildTaskStatTile('Pending', '$pendingTasks', DuoColors.warning80),
                          const SizedBox(width: 12),
                          _buildTaskStatTile('Total Created', '$totalTasks', DuoColors.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhiteStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildTaskStatTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: DuoColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
