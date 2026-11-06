import 'package:flutter/material.dart';

class DuoColors {
  // Brand Design Tokens
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryDark = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFA78BFA);
  
  static const Color background = Color(0xFFF8F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color lavenderSurface = Color(0xFFF0ECFC);
  static const Color lavenderBorder = Color(0xFFE2DCF3);
  
  // Text Tokens (User specified #282238)
  static const Color textPrimary = Color(0xFF282238);
  static const Color textSecondary = Color(0xFF6B667B);
  static const Color textMuted = Color(0xFF9E99AC);
  static const Color border = Color(0xFFE2DCF3);

  // Accents & Alerts
  static const Color peachAccent = Color(0xFFFFE2D6);
  static const Color mintAccent = Color(0xFFD9F2E5);
  static const Color success = Color(0xFF10B981);
  static const Color warning80 = Color(0xFFF59E0B);
  static const Color limit100 = Color(0xFFEA580C);
  static const Color overBudget = Color(0xFFEF4444);

  // Priority Colors
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF3B82F6);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: DuoColors.primary,
      scaffoldBackgroundColor: DuoColors.background,
      colorScheme: const ColorScheme.light(
        primary: DuoColors.primary,
        surface: DuoColors.surface,
        onSurface: DuoColors.textPrimary,
        error: DuoColors.overBudget,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: DuoColors.background,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: DuoColors.textPrimary),
        titleTextStyle: TextStyle(
          color: DuoColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: DuoColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: DuoColors.lavenderBorder, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DuoColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DuoColors.primary,
          side: const BorderSide(color: DuoColors.primary, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DuoColors.lavenderBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DuoColors.lavenderBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DuoColors.primary, width: 1.8),
        ),
        hintStyle: const TextStyle(color: DuoColors.textMuted, fontSize: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: DuoColors.primary,
        unselectedItemColor: DuoColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
