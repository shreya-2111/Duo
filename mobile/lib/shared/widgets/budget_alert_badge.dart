import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class BudgetAlertBadge extends StatelessWidget {
  final String alertLevel;
  final double percentage;
  final String? message;
  final bool isCompact;

  const BudgetAlertBadge({
    super.key,
    required this.alertLevel,
    required this.percentage,
    this.message,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    if (alertLevel == 'OVER_BUDGET' || percentage > 100) {
      bg = const Color(0xFFFEE2E2);
      fg = DuoColors.overBudget;
      icon = Icons.error_outline;
      label = isCompact ? 'Over Budget' : 'Budget Exceeded (>100%)';
    } else if (alertLevel == 'REACHED_100' || percentage == 100) {
      bg = const Color(0xFFFFEDD5);
      fg = DuoColors.limit100;
      icon = Icons.warning_amber_rounded;
      label = isCompact ? '100% Reached' : 'Monthly Limit Reached (100%)';
    } else if (alertLevel == 'WARNING_80' || percentage >= 80) {
      bg = const Color(0xFFFEF3C7);
      fg = DuoColors.warning80;
      icon = Icons.info_outline;
      label = isCompact ? '80% Spent' : 'Budget Alert (≥80% Spent)';
    } else {
      bg = const Color(0xFFDCFCE7);
      fg = DuoColors.success;
      icon = Icons.check_circle_outline;
      label = isCompact ? 'On Track' : 'Within Budget (<80%)';
    }

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (message != null && message!.isNotEmpty)
                  Text(
                    message!,
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

