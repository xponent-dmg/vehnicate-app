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
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget container = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        // Linear gradient for a slight "shine" from top-left
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (backgroundColor ?? Colors.white).withOpacity(1),
            (backgroundColor ?? Colors.white).withOpacity(0.2),
          ],
        ),
        borderRadius: borderRadius,
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.1),
          width: 1,
          style: BorderStyle.values[hasBorder ? 1 : 0],
        ),
        boxShadow:
            hasShadow
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
                : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: container);
    }

    return container;
  }
}
