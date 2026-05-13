import 'dart:math';
import 'dart:ui';

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:opsin/Pages/drive/drive_analyze_page.dart';
import 'package:opsin/Widgets/glass_lite_container.dart';

/// A reusable pull-to-refresh wrapper.
///
/// Behaviour:
/// - The scrollable child does NOT move.
/// - A 4-pointed curved star (astroid) slides down from above the top edge
///   as the user pulls, fading in proportionally.
/// - While loading, the star spins continuously via [RotationTransition].
///
/// Usage:
/// ```dart
/// StarRefreshIndicator(
///   onRefresh: () async { ... },
///   child: ListView(...),
/// )
/// ```
class StarRefreshIndicator extends StatefulWidget {
  const StarRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<StarRefreshIndicator> createState() => _StarRefreshIndicatorState();
}

class _StarRefreshIndicatorState extends State<StarRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Slower rotation
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final starColor = Theme.of(context).primaryColor;

    return CustomRefreshIndicator(
      onRefresh: widget.onRefresh,
      onStateChanged: (change) {
        // Start spinning as soon as the user begins pulling
        if (change.currentState == IndicatorState.dragging ||
            change.currentState == IndicatorState.armed ||
            change.currentState == IndicatorState.loading) {
          if (!_rotationController.isAnimating) {
            _rotationController.repeat();
          }
        } else if (change.currentState == IndicatorState.finalizing ||
            change.currentState == IndicatorState.idle) {
          // Let it spin through the exit animation, then stop
          _rotationController.stop();
          _rotationController.reset();
        }
      },
      builder: (context, child, controller) {
        return Stack(
          children: [
            // Child stays put — no translation
            child,

            // Star: slides in from above + fades, driven solely by [controller]
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final progress = controller.value.clamp(0.0, 1.0);
                if (progress == 0) return const SizedBox.shrink();

                // Slides from above the screen → 36 px from top
                final topOffset = lerpDouble(-30.0, 72.0, progress)!;

                return Positioned(
                  top: topOffset,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Opacity(
                      opacity: progress,
                      child: GlassLiteContainer(
                        padding: const EdgeInsets.all(12),
                        borderRadius: BorderRadius.circular(100),
                        blurSigma: 8.0,
                        backgroundColor: DriveAnalyzeConstants.cardBackground,
                        child: RotationTransition(
                          turns: _rotationController,
                          child: CustomPaint(
                            size: const Size(24, 24),
                            painter: _AstroidStarPainter(color: starColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

/// Draws a smooth 4-pointed star using the astroid curve:
///   x = R · cos³(t),  y = R · sin³(t)
///
/// This produces concave, softly-curved sides between the four cardinal tips.
class _AstroidStarPainter extends CustomPainter {
  const _AstroidStarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true;

    final fillPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

    final double fullSize = (size.width / 2) - 0.75; // Adjust for stroke width
    final center = Offset(size.width / 2, size.height / 2);
    final path = Path();

    // Control point distance for the quadratic curves
    // This controls how much the sides curve inward
    final double controlPointDistance = fullSize * 0.4;

    for (int i = 0; i < 4; i++) {
      final angle = (i * pi / 2); // 90 degree rotation for each point

      // Calculate point position
      final pointX = center.dx + cos(angle) * fullSize;
      final pointY = center.dy + sin(angle) * fullSize;

      if (i == 0) {
        path.moveTo(pointX, pointY);
      } else {
        // Calculate control point for the quadratic curve
        final prevAngle = ((i - 1) * pi / 2);
        final midAngle = prevAngle + pi / 4; // Halfway between points

        final controlX = center.dx + cos(midAngle) * controlPointDistance;
        final controlY = center.dy + sin(midAngle) * controlPointDistance;

        // Draw curved line to next point
        path.quadraticBezierTo(controlX, controlY, pointX, pointY);
      }
    }

    // Close the path with final curve
    final controlX = center.dx + cos(7 * pi / 4) * controlPointDistance;
    final controlY = center.dy + sin(7 * pi / 4) * controlPointDistance;

    path.quadraticBezierTo(controlX, controlY, center.dx + fullSize, center.dy);

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_AstroidStarPainter oldDelegate) =>
      oldDelegate.color != color;
}
