import 'package:flutter/material.dart';
import 'package:vehnway/core/constants/app_gradients.dart';

class DriveDetailsConstants {
  // Colors
  static const Color primaryBackground = AppColors.deepBlack;
  static const Color cardBackground = AppColors.background;
  static const Color accentPurple = AppColors.mutedPurple;
  static const Color lightPurple = AppColors.vividPurple;
  static const Color darkPurple = AppColors.deepPurpleAccent;
  static const Color successGreen = AppColors.success;
  static const Color warningRed = AppColors.danger;
  static const Color warningOrange = Colors.orange;
  static const Color dividerColor = AppColors.divider;

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w700,
  );

  static const TextStyle subtitleStyle = TextStyle(
    color: Colors.white70,
    fontSize: 14,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w500,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w600,
  );

  static const TextStyle metricValueStyle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w700,
  );

  static const TextStyle metricLabelStyle = TextStyle(
    color: Colors.white70,
    fontSize: 12,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w500,
  );

  static const TextStyle improvementStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w700,
  );

  // Dimensions
  static const double cardRadius = 12.0;
  static const double horizontalPadding = 24.0;
  static const double chartHeight = 200.0;
}
