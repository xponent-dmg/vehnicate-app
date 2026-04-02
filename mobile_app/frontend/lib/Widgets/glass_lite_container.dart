import 'dart:ui';
import 'package:flutter/material.dart';

class GlassLiteContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry borderRadius;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool hasShadow;
  final bool hasBorder;
  final double blurSigma;

  const GlassLiteContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.hasShadow = false,
    this.hasBorder = false,
    this.blurSigma = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = backgroundColor ?? Theme.of(context).colorScheme.surface;

    Widget container = ClipRRect(
      borderRadius: borderRadius as BorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            color: baseColor.withOpacity(0.55), // flat, readable frost
            borderRadius: borderRadius,
            border:
                hasBorder
                    ? Border.all(
                      color: borderColor ?? Colors.white.withOpacity(0.2),
                      width: 1,
                    )
                    : null,
            boxShadow:
                hasShadow
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : null,
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: container);
    }

    return container;
  }
}
