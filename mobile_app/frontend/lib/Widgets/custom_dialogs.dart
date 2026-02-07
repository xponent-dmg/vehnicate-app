import 'package:flutter/material.dart';

class CustomConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final Color? confirmTextColor;
  final Color? backgroundColor;
  final TextStyle? titleStyle;
  final TextStyle? contentStyle;
  final TextStyle? cancelTextStyle;

  const CustomConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.confirmText = "Confirm",
    this.cancelText = "Cancel",
    this.confirmTextColor,
    this.backgroundColor,
    this.titleStyle,
    this.contentStyle,
    this.cancelTextStyle,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
    String confirmText = "Confirm",
    String cancelText = "Cancel",
    Color? confirmTextColor,
    Color? backgroundColor,
  }) {
    return showDialog(
      context: context,
      builder:
          (context) => CustomConfirmationDialog(
            title: title,
            content: content,
            onConfirm: onConfirm,
            confirmText: confirmText,
            cancelText: cancelText,
            confirmTextColor: confirmTextColor,
            backgroundColor: backgroundColor,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: backgroundColor ?? const Color(0xFF0E0E1A),
      elevation: 5,
      title: Text(
        title,
        style:
            titleStyle ??
            const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w700,
            ),
      ),
      content: Text(
        content,
        style:
            contentStyle ??
            const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w500,
            ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            cancelText,
            style:
                cancelTextStyle ??
                const TextStyle(
                  color: Colors.blue, // Default flutter blue or customizable
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            // Usually we don't pop here if the action is async and handles its own flow (like logout showing another dialog)
            // But if it's a simple confirmation that just runs logic and closes, we might want to pop.
            // For logout, `_showLogoutDialog` calls `_handleLogout` which navigates.
            // But `_showLogoutDialog` passed a function `() => _handleLogout(context)`.
            // The original code passed `_handleLogout(context)` which does NOT pop the confirmation dialog first?
            // Wait, looking at original code:
            // onPressed: () => _handleLogout(context),
            // And _handleLogout starts with showDialog (loading).
            // So the confirmation dialog STAYS OPEN underneath the loading dialog?
            // Usually you pop confirmation before showing loading.
            // BUT, the original code did NOT pop confirmation dialog in `onPressed`.
            // `_handleLogout` does not pop it either?
            // Wait, `_handleLogout` calls `Navigator.of(context).pop()` (line 114) and then `pushNamedAndRemoveUntil`.
            // Line 114 pops the loading dialog.
            // Does it pop the confirmation dialog?
            // If confirmation dialog is on stack, then loading dialog is pushed on top.
            // `Navigator.pop` pops the top one (loading).
            // Then `pushNamedAndRemoveUntil` removes everything. So it works.
          },
          child: Text(
            confirmText,
            style: TextStyle(
              color: confirmTextColor ?? const Color(0xA5FF0000),
              fontSize: 15,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class CustomLoadingDialog extends StatelessWidget {
  final String message;
  final Color? backgroundColor;
  final TextStyle? messageStyle;

  const CustomLoadingDialog({
    super.key,
    required this.message,
    this.backgroundColor,
    this.messageStyle,
  });

  static Future<void> show(
    BuildContext context, {
    String message = 'Loading...',
    Color? backgroundColor,
    bool barrierDismissible = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder:
          (context) => CustomLoadingDialog(
            message: message,
            backgroundColor: backgroundColor,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: backgroundColor ?? const Color(0xFF2d2d44),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Theme.of(context).primaryColor),
            const SizedBox(width: 20),
            Text(
              message,
              style: messageStyle ?? const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
