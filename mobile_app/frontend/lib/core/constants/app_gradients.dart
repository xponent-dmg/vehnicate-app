// lib/core/constants/app_gradients.dart

import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF555FDB);
  static const Color secondary = Color(0xFF2d2d44);
  static const Color accent = Color(0xFF8157E8);
  static const Color logoPurple = Color(0xFF4C40BB);
  static const Color lightPurple = Color(0xFF7B86F0);
  static const Color darkPurple = Color(0xFF191B33);

  // Background Colors
  static const Color background = Color(0xFF2d2d44);
  static const Color darkBackground = Color(0xFF0E0E1A);
  static const Color surface = Color(0xFF3d3d54);
  static const Color cardBackground = Color(0xFF2d2d44);
  static const Color deepBlack = Color(0xFF01010D);
  static const Color deepBlueBackground = Color(0xFF1a1a2e);
  static const Color darkGreyBackground = Color(0xFF1B1D25);

  // Status Colors
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3498DB);
  static const Color success = Color(0xFF4CAF50);
  static const Color danger = Color(0xFFF24E1E);
  static const Color logout = Color(0xFFF24E1E);
  static const Color delete = Color(0xA5FF0000);

  // Accents & Gradients
  static const Color mutedPurple = Color(0xFF765FD1);
  static const Color vividPurple = Color(0xFF9217BB);
  static const Color vibrantPurple = Color(0xFF8E44AD);
  static const Color deepPurpleAccent = Color(0xFF403862);
  static const Color buttonBlue = Color(0xFF5B60F8);
  static const Color divider = Color(0x33B0A4AD);

  // Severity/Event Colors (from Drive Details)
  static const Color severityCritical = Color(0xFFEF4444);
  static const Color severityHigh = Color(0xFFDC2626);
  static const Color severityMedium = Color(0xFFF59E0B);
  static const Color severityLow = Color(0xFF8B5CF6);
  static const Color severityInfo = Color(0xFF06B6D4);
  static const Color severitySuccess = Color(0xFF10B981);

  // Chart/Misc Colors
  static const Color chartYellow = Color(0xFFFCD34D);
  static const Color chartAmber = Color(0xFFFBBF24);
  static const Color chartGold = Color(0xFFFEF08A);
}

class AppGradients {
  static const LinearGradient mainBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, 0.8, 1],
    colors: [Colors.black, Color(0xFF191B33), Color(0xFF292D54)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppColors.primary, Color(0xFF9217BB)],
  );
}

class ShimmerConstants {
  static const shimmerBase = Color(0xFF3a3a52);
  static const shimmerHighlight = Color(0xFF5c5c7a);
}
