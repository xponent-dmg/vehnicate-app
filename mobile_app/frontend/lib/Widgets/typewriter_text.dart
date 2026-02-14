import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class TypewriterText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final VoidCallback? onFinished;

  const TypewriterText(
    this.text, {
    super.key,
    this.style,
    this.duration = const Duration(milliseconds: 2000),
    this.onFinished,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate speed based on duration and text length
    // If text is empty, avoid division by zero
    final int charCount = text.isNotEmpty ? text.length : 1;
    final Duration speed = Duration(
      milliseconds: duration.inMilliseconds ~/ charCount,
    );

    return SizedBox(
      child: DefaultTextStyle(
        style: style ?? const TextStyle(),
        child: AnimatedTextKit(
          key: ValueKey(text), // Rebuilds animation when text changes
          animatedTexts: [
            TypewriterAnimatedText(text, speed: speed, cursor: '_'),
          ],
          totalRepeatCount: 1,
          onFinished: onFinished,
          displayFullTextOnTap: true,
          stopPauseOnTap: true,
        ),
      ),
    );
  }
}
