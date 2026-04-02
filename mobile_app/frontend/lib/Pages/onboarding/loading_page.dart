import 'package:flutter/material.dart';
import 'package:vehnicate_frontend/core/constants/app_gradients.dart';
import '../../Widgets/animations/rising_particles.dart';
import '../../Widgets/animations/step_rotating_shape.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  Widget build(BuildContext context) {
    // Determine background color based on theme
    // final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Colors.transparent;
    final textColor = Colors.white70;

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: BoxDecoration(gradient: AppGradients.mainBackground),
        child: SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rising Particles Background
              Positioned.fill(
                child: RisingParticles(),
              ),

              // Central Loading Indicator
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: StepRotatingShape(
                      size: 25,
                      rotationDuration: const Duration(milliseconds: 600),
                      pauseDuration: const Duration(milliseconds: 300),
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Calibrating the engine...',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
