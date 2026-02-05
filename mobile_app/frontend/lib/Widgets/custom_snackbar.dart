import 'package:flutter/material.dart';

/// A custom snackbar widget that matches the app's theme
class CustomSnackBar {
  /// Shows a success snackbar
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: const Color(0xFF8E44AD),
      iconColor: Colors.white,
    );
  }

  /// Shows an error snackbar
  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: const Color(0xFFE74C3C),
      iconColor: Colors.white,
    );
  }

  /// Shows a warning snackbar
  static void showWarning(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.warning_rounded,
      backgroundColor: const Color(0xFFF39C12),
      iconColor: Colors.white,
    );
  }

  /// Shows an info snackbar
  static void showInfo(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: const Color(0xFF3498DB),
      iconColor: Colors.white,
    );
  }

  /// Shows a custom snackbar with full customization
  static void showCustom(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? backgroundColor,
    Color? iconColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: icon,
      backgroundColor: backgroundColor ?? const Color(0xFF2d2d44),
      iconColor: iconColor ?? Colors.white,
      textColor: textColor ?? Colors.white,
      duration: duration,
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    IconData? icon,
    required Color backgroundColor,
    required Color iconColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        elevation: 4,
      ),
    );
  }
}
