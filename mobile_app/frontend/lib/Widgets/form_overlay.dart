import 'package:flutter/material.dart';
import 'glass_lite_container.dart';

/// Enum to define the type of form field
enum FormFieldType { text, date }

/// Configuration for a single form field
class FormFieldConfig {
  final String label;
  final String hint;
  final IconData icon;
  final bool isRequired;
  final TextEditingController controller;
  final FormFieldType type;

  final TextInputType? keyboardType;
  final bool isPassword;
  bool obscureText;

  FormFieldConfig({
    required this.label,
    required this.hint,
    required this.icon,
    this.isRequired = true,
    required this.controller,
    this.type = FormFieldType.text,
    this.keyboardType,
    this.isPassword = false,
    bool? obscureText,
  }) : obscureText = obscureText ?? isPassword;
}

/// Reusable form overlay widget
class FormOverlay {
  /// Show the form overlay dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required List<FormFieldConfig> fields,
    required String submitButtonText,
    required Future<void> Function() onSubmit,
    VoidCallback? onSuccess,
    Function(dynamic error)? onError,
  }) {
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    return showGeneralDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (
        BuildContext buildContext,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Center(
              child: Dialog(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: GlassLiteContainer(
                  backgroundColor: const Color(0xFF0E0E1A),
                  borderRadius: BorderRadius.circular(20),
                  hasBorder: true,
                  hasShadow: true,
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,

                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!isSubmitting)
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.white70,
                                  ),
                                  onPressed:
                                      () => Navigator.of(buildContext).pop(),
                                ),
                            ],
                          ),
                          SizedBox(height: 16),

                          // Form fields
                          ...fields.asMap().entries.map((entry) {
                            final index = entry.key;
                            final field = entry.value;
                            final isLast = index == fields.length - 1;
                            final textInputAction =
                                isLast
                                    ? TextInputAction.done
                                    : TextInputAction.next;

                            return Column(
                              children: [
                                if (index > 0) SizedBox(height: 16),
                                field.type == FormFieldType.date
                                    ? _buildDateField(
                                      context: context,
                                      controller: field.controller,
                                      label: field.label,
                                      hint: field.hint,
                                      icon: field.icon,
                                      isRequired: field.isRequired,
                                      setState: setState,
                                    )
                                    : _buildTextField(
                                      context: context,
                                      controller: field.controller,
                                      label: field.label,
                                      hint: field.hint,
                                      icon: field.icon,
                                      isRequired: field.isRequired,
                                      keyboardType: field.keyboardType,
                                      obscureText: field.obscureText,
                                      isPassword: field.isPassword,
                                      onTogglePassword: () {
                                        setState(() {
                                          field.obscureText =
                                              !field.obscureText;
                                        });
                                      },
                                      textInputAction: textInputAction,
                                    ),
                              ],
                            );
                          }),

                          SizedBox(height: 24),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  isSubmitting
                                      ? null
                                      : () async {
                                        if (!formKey.currentState!.validate()) {
                                          return;
                                        }

                                        setState(() {
                                          isSubmitting = true;
                                        });

                                        try {
                                          await onSubmit();

                                          // Close dialog
                                          if (buildContext.mounted) {
                                            Navigator.of(buildContext).pop();
                                          }

                                          // Call success callback
                                          if (onSuccess != null) {
                                            onSuccess();
                                          }
                                        } catch (e) {
                                          // Call error callback
                                          if (onError != null) {
                                            onError(e);
                                          }
                                        } finally {
                                          if (context.mounted) {
                                            setState(() {
                                              isSubmitting = false;
                                            });
                                          }
                                        }
                                      },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBackgroundColor: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.5),
                              ),
                              child:
                                  isSubmitting
                                      ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Text(
                                        submitButtonText,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Scale + Fade animation
        const curve = Curves.easeOutCubic;

        var scaleTween = Tween<double>(
          begin: 0.85,
          end: 1.0,
        ).chain(CurveTween(curve: curve));
        var fadeTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: curve));

        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
    );
  }

  /// Build a text field
  static Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = true,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool isPassword = false,
    VoidCallback? onTogglePassword,
    TextInputAction? textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (isRequired ? ' *' : ''),
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          textInputAction: textInputAction,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white38),
            prefixIcon: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            suffixIcon:
                isPassword
                    ? IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility
                            : Icons.visibility_off_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: onTogglePassword,
                    )
                    : null,
            filled: true,
            fillColor: Color(0xFF3d3d54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator:
              isRequired
                  ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'This field is required';
                    }
                    return null;
                  }
                  : null,
          keyboardType: keyboardType,
        ),
      ],
    );
  }

  /// Build a date picker field
  static Widget _buildDateField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required StateSetter setState,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (isRequired ? ' *' : ''),
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white38),
            prefixIcon: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            filled: true,
            fillColor: Color(0xFF3d3d54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator:
              isRequired
                  ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'This field is required';
                    }
                    return null;
                  }
                  : null,
          readOnly: true,
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().toLocal(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (picked != null) {
              setState(() {
                controller.text = picked.toIso8601String().split('T')[0];
              });
            }
          },
        ),
      ],
    );
  }
}
