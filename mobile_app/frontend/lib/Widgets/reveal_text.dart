import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class RevealText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final Duration delay;

  const RevealText(
    this.text, {
    super.key,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate speed based on duration and text length
    final int charCount = text.isNotEmpty ? text.length : 1;
    final Duration speed = Duration(
      milliseconds: duration.inMilliseconds ~/ charCount,
    );

    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done &&
            delay != Duration.zero) {
          return Text('', style: style); // Show nothing while waiting for delay
        }

        return SizedBox(
          child: DefaultTextStyle(
            style: style ?? const TextStyle(),
            child: AnimatedTextKit(
              key: ValueKey(text),
              animatedTexts: [TyperAnimatedText(text, speed: speed)],
              isRepeatingAnimation: false,
              displayFullTextOnTap: true,
            ),
          ),
        );
      },
    );
  }
}
