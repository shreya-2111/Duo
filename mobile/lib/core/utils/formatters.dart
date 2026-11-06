import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DuoFormatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String formatCurrency(num amount) {
    if (amount == amount.truncateToDouble()) {
      return _compactCurrencyFormat.format(amount);
    }
    return _currencyFormat.format(amount);
  }

  static String formatDate(DateTime? date) {
    if (date == null) return 'No date';
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatShortDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String apiDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static IconData iconForCategory(String? category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Travel':
        return Icons.directions_subway;
      case 'Shopping':
        return Icons.shopping_bag_outlined;
      case 'Health':
        return Icons.health_and_safety_outlined;
      case 'Bills':
        return Icons.receipt_long_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  static Color colorForCategory(String? category) {
    switch (category) {
      case 'Food':
        return const Color(0xFFF59E0B);
      case 'Travel':
        return const Color(0xFF3B82F6);
      case 'Shopping':
        return const Color(0xFFEC4899);
      case 'Health':
        return const Color(0xFF10B981);
      case 'Bills':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

