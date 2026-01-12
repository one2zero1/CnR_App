import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF64B5F6);

  // Role colors
  static const Color police = Color(0xFF1565C0); // Blue 800
  static const Color policeLight = Color(0xFF42A5F5); // Blue 400
  static const Color thief = Color(0xFFD32F2F); // Red 700
  static const Color thiefLight = Color(0xFFEF5350); // Red 400

  // Status colors
  static const Color danger = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color success = Color(0xFF66BB6A);
  static const Color safe = Color(0xFF4CAF50);

  // Background colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;

  // Semantic Colors (Added for Refactoring)
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70;
  static const Color transparent = Colors.transparent;
  static const Color black = Colors.black;
  static Color black10 = Colors.black.withOpacity(0.1);
  static Color black20 = Colors.black.withOpacity(0.2);
  static Color white20 = Colors.white.withOpacity(0.2);
  static Color policeOverlay = police.withOpacity(0.3);
  static Color thiefOverlay = thief.withOpacity(0.3);

  // Grayscale & Neutral
  static const Color grey200 = Color(0xFFEEEEEE); // Colors.grey[200]
  static const Color grey100 = Color(0xFFF5F5F5); // Colors.grey[100]

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color timerText = Color(0xFFFF5722);
}
