import 'package:flutter/material.dart';

class AppColors {
  // ===== PRIMARY GOLD =====
  static const Color primary      = Color(0xFFF4A324);
  static const Color primaryLight = Color(0xFFFFB74D);
  static const Color primaryDark  = Color(0xFFE08E10);

  // ===== SECONDARY =====
  static const Color secondary      = Color(0xFFF4A324);
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark  = Color(0xFFE08E10);

  // ===== BACKGROUNDS =====
  static const Color background     = Color(0xFF0A0E27);
  static const Color bgSecondary    = Color(0xFF0F1535);
  static const Color surface        = Color(0xFF141B45);
  static const Color cardBackground = Color(0xFF0F1535);
  static const Color sidebarBg      = Color(0xFF0D1130);

  // ===== LAWYER COLORS =====
  static const Color lawyerPrimary      = Color(0xFF7B61FF);
  static const Color lawyerPrimaryLight = Color(0xFF9D85FF);
  static const Color lawyerPrimaryDark  = Color(0xFF5A3FF0);

  // ===== TEXT =====
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8892B0);
  static const Color textMuted     = Color(0xFF4A5580);
  static const Color textLight     = Color(0xFFFFFFFF);

  // ===== STATUS =====
  static const Color success = Color(0xFF00C896);
  static const Color error   = Color(0xFFFF4757);
  static const Color warning = Color(0xFFF4A324);
  static const Color info    = Color(0xFF3498DB);

  // ===== CASE STATUS =====
  static const Color statusOpen       = Color(0xFF00C896);
  static const Color statusInProgress = Color(0xFFF4A324);
  static const Color statusClosed     = Color(0xFF8892B0);
  static const Color statusUrgent     = Color(0xFFFF4757);

  // ===== LAWYER CASE STATUS =====
  static const Color lawyerStatusOpen       = Color(0xFF00C896);
  static const Color lawyerStatusInProgress = Color(0xFFF4A324);
  static const Color lawyerStatusClosed     = Color(0xFF8892B0);
  static const Color lawyerStatusUrgent     = Color(0xFFFF4757);

  // ===== BORDERS =====
  static const Color border  = Color(0x33F4A324);
  static const Color divider = Color(0x1AF4A324);

  // ===== ADDITIONAL =====
  static const Color charcoal      = Color(0xFF141B45);
  static const Color charcoalLight = Color(0xFF1E2860);
  static const Color charcoalDark  = Color(0xFF0A0E27);

  // ===== GRADIENTS =====
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
    colors: [Color(0xFFF4A324), Color(0xFFFFB74D)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0E27), Color(0xFF0F1535)],
  );
}
