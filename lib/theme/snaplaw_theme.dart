import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════
// SNAPLAW DESIGN SYSTEM — Dark Navy + Gold Legal Theme
// ═══════════════════════════════════════════════════════

class SnapLawColors {
  static const primary       = Color(0xFFF4A324);
  static const primaryDark   = Color(0xFFE08E10);
  static const primaryLight  = Color(0xFFFFB74D);
  static const accent        = Color(0xFFF4A324);
  static const accentLight   = Color(0xFFFFB74D);

  static const clientBlue    = Color(0xFF3B82F6);
  static const lawyerPurple  = Color(0xFF7B61FF);
  static const citizenGreen  = Color(0xFF00C896);
  static const adminRed      = Color(0xFFFF4757);

  static const bgDeep        = Color(0xFF0A0E27);
  static const bgDark        = Color(0xFF0F1535);
  static const bgMid         = Color(0xFF141B45);
  static const bgCard        = Color(0xFF0F1535);
  static const bgSidebar     = Color(0xFF0D1130);

  static const glass12       = Color(0x1EFFFFFF);
  static const glass15       = Color(0x26FFFFFF);
  static const glass20       = Color(0x33FFFFFF);
  static const glassBorder   = Color(0x33F4A324);

  static const textWhite     = Color(0xFFFFFFFF);
  static const textMuted     = Color(0xFF8892B0);
  static const textHint      = Color(0xFF4A5580);

  static const success       = Color(0xFF00C896);
  static const warning       = Color(0xFFF4A324);
  static const danger        = Color(0xFFFF4757);
  static const info          = Color(0xFF3498DB);
  static const purple        = Color(0xFF7B61FF);
}

class SnapLawGradients {
  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0E27), Color(0xFF0F1535), Color(0xFF141B45)],
    stops: [0.0, 0.5, 1.0],
  );

  static const client = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF0A0E27), Color(0xFF0D1535), Color(0xFF1A2A5C)],
  );

  static const lawyer = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF0A0E27), Color(0xFF0D0D2A), Color(0xFF1A1A4E)],
  );

  static const citizen = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF0A0E27), Color(0xFF0A1A10), Color(0xFF0A2A18)],
  );

  static const gold = LinearGradient(
    colors: [Color(0xFFF4A324), Color(0xFFFFB74D), Color(0xFFF4A324)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static const sidebar = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [Color(0xFF0D1130), Color(0xFF0A0E27)],
  );
}
