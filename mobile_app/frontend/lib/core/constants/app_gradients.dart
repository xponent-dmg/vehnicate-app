// lib/core/constants/app_gradients.dart

import 'package:flutter/material.dart';

class AppGradients {
  static const LinearGradient mainBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, 0.8, 1],
    colors: [Colors.black, Color(0xFF191B33), Color(0xFF292D54)],
  );
}

class ShimmerConstants {
  static const shimmerBase = Color(0xFF3a3a52);
  static const shimmerHighlight = Color(0xFF5c5c7a);
}
