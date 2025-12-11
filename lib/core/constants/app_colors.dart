import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1E3A5F);
  static const Color primaryLight = Color(0xFF2E5A8F);
  static const Color primaryDark = Color(0xFF0E2A4F);

  // Secondary Colors
  static const Color secondary = Color(0xFFD4AF37);
  static const Color secondaryLight = Color(0xFFE4BF47);
  static const Color secondaryDark = Color(0xFFC49F27);

  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Colors.white;

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Case Status Colors
  static const Color statusOpen = Color(0xFF4CAF50);
  static const Color statusInProgress = Color(0xFFFFA726);
  static const Color statusClosed = Color(0xFF9E9E9E);
  static const Color statusUrgent = Color(0xFFE53935);

  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
}
