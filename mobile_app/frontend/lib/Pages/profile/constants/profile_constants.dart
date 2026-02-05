import 'package:flutter/material.dart';

class ProfileConstants {
  // Colors
  static const Color primaryBackground = Color(0xFF01010D);
  static const Color cardBackground = Color(0xFF0E0E1A);
  static const Color accentPurple = Color(0xFF765FD1);
  static const Color lightPurple = Color(0xFF9217BB);
  static const Color darkPurple = Color(0xFF403862);
  static const Color logoutRed = Color(0xFFF24E1E);
  static const Color deleteRed = Color(0xA5FF0000);
  static const Color dividerColor = Color(0x33B0A4AD);

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
