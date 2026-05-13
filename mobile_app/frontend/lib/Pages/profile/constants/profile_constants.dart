import 'package:flutter/material.dart';
import 'package:opsin/core/constants/app_gradients.dart';

class ProfileConstants {
  // Colors
  static const Color primaryBackground = AppColors.deepBlack;
  static const Color cardBackground = AppColors.darkBackground;
  static const Color accentPurple = AppColors.mutedPurple;
  static const Color lightPurple = AppColors.vividPurple;
  static const Color darkPurple = AppColors.deepPurpleAccent;
  static const Color logoutRed = AppColors.logout;
  static const Color deleteRed = AppColors.delete;
  static const Color dividerColor = AppColors.divider;

  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, 0.8, 1],
    colors: [Colors.black, Color(0xFF191B33), Color(0xFF292D54)],
  );

  // Text Styles
  static const TextStyle nameStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w700,
  );

  static const TextStyle usernameStyle = TextStyle(
    color: Colors.white,
    fontSize: 13,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w500,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w700,
  );

  static const TextStyle labelStyle = TextStyle(
    color: Colors.white70,
    fontSize: 14,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w500,
  );

  static const TextStyle valueStyle = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w500,
  );

  static const TextStyle logoutStyle = TextStyle(
    color: logoutRed,
    fontSize: 10,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w600,
  );

  static const TextStyle deleteStyle = TextStyle(
    color: deleteRed,
    fontSize: 15,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w600,
  );

  static const TextStyle metricValueStyle = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w700,
  );

  static const TextStyle metricLabelStyle = TextStyle(
    color: Colors.white,
    fontSize: 10,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w700,
  );

  // Dimensions
  static const double cardHeight = 50.0;
  static const double cardRadius = 8.0;
  static const double avatarSize = 87.0;
  static const double metricCircleSize = 60.0;
  static const double horizontalPadding = 28.0;
}
