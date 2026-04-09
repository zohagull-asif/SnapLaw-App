import 'package:flutter/material.dart';

class AppColors {
  // ===== LAWYER COLORS (Burgundy/Gold Theme) =====
  // Primary Colors for Lawyer Dashboard
  static const Color lawyerPrimary = Color(0xFF8B1538);
  static const Color lawyerPrimaryLight = Color(0xFFA52A4A);
  static const Color lawyerPrimaryDark = Color(0xFF6B0028);

  // ===== CLIENT & AUTH COLORS (Original Blue/Pink Theme) =====
  // Primary Colors for Client Dashboard & Auth Screens (Original)
  static const Color primary = Color(0xFF1E3A5F);
  static const Color primaryLight = Color(0xFF2E5A8F);
  static const Color primaryDark = Color(0xFF0E2A4F);

  // Secondary Colors (Gold/Amber accent - shared)
  static const Color secondary = Color(0xFFD4AF37);
  static const Color secondaryLight = Color(0xFFFFD700);
  static const Color secondaryDark = Color(0xFFB8941F);

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

  // Case Status Colors (Original for Client)
  static const Color statusOpen = Color(0xFF4CAF50);
  static const Color statusInProgress = Color(0xFFFFA726);
  static const Color statusClosed = Color(0xFF9E9E9E);
  static const Color statusUrgent = Color(0xFFE53935);

  // Lawyer-specific Case Status Colors
  static const Color lawyerStatusOpen = Color(0xFF27AE60);
  static const Color lawyerStatusInProgress = Color(0xFFD4AF37);
  static const Color lawyerStatusClosed = Color(0xFF95A5A6);
  static const Color lawyerStatusUrgent = Color(0xFF8B1538);

  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // Additional Colors
  static const Color charcoal = Color(0xFF2C3E50);
  static const Color charcoalLight = Color(0xFF34495E);
  static const Color charcoalDark = Color(0xFF1A252F);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient lawyerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lawyerPrimary, lawyerPrimaryLight],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
  );
}
