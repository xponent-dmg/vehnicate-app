import 'dart:async';
import 'package:flutter/material.dart';

/// A custom snackbar widget that matches the app's theme
class CustomSnackBar {
  /// Shows a success snackbar
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: Theme.of(context).primaryColor,
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
    // Bumped default duration slightly so users have time to read/expand
    Duration duration = const Duration(seconds: 5),
  }) {
    if (!context.mounted) return;

    // Define the state variable OUTSIDE the builder so it remembers
    // its state during rebuilds of the snackbar content.
    bool isExpanded = false;
    final bool hasLongMessage = message.length > 60;

    // If the message is long, we set the native duration to 1 minute to give
    // the user time to read it if they click "View More".
    // We will manually close it after the original [duration] (e.g. 5s)
    // if the user has NOT expanded it.
    final Duration finalDuration =
        hasLongMessage ? const Duration(minutes: 1) : duration;

    ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? controller;

    controller = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: StatefulBuilder(
          builder: (context, setState) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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

                // Main Text and "View More" area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 6.0,
                    ), // Align text nicely with the icon
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          maxLines: isExpanded ? null : 2,
                          overflow:
                              isExpanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor ?? Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        // Only show the toggle if the message is relatively long
                        if (hasLongMessage)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isExpanded = !isExpanded;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                isExpanded ? "Show Less" : "View More",
                                style: TextStyle(
                                  color:
                                      textColor?.withOpacity(0.8) ??
                                      Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Cancel (X) Button
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      color: textColor?.withOpacity(0.8) ?? Colors.white70,
                      size: 20,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        dismissDirection:
            DismissDirection.horizontal, // Keeps swipe-to-dismiss active
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: finalDuration,
        elevation: 4,
        onVisible: () {
          if (hasLongMessage) {
            Timer(duration, () {
              // If the snackbar is NOT expanded after the initial duration (5s), close it.
              // If it IS expanded, leave it open (it will close after finalDuration, i.e., 1 min).
              if (!isExpanded && context.mounted) {
                controller?.close();
              }
            });
          }
        },
      ),
    );
  }
}
