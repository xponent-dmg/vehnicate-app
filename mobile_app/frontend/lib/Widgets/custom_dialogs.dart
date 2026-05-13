import 'package:flutter/material.dart';
import 'glass_lite_container.dart';
import 'package:opsin/core/constants/app_gradients.dart';

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
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassLiteContainer(
        backgroundColor: backgroundColor ?? AppColors.darkBackground,
        borderRadius: BorderRadius.circular(24),
        hasBorder: true,
        hasShadow: true,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
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
            const SizedBox(height: 12),
            Text(
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    cancelText,
                    style:
                        cancelTextStyle ??
                        const TextStyle(
                          color: Colors.blue,
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    onConfirm();
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
            ),
          ],
        ),
      ),
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassLiteContainer(
        backgroundColor: backgroundColor ?? AppColors.background,
        borderRadius: BorderRadius.circular(20),
        hasBorder: true,
        hasShadow: true,
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
