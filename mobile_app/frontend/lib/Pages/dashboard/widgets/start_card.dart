import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vehnway/Providers/vehicle_provider.dart';
import 'package:vehnway/Widgets/custom_snackbar.dart';
import 'package:vehnway/Widgets/glass_lite_container.dart';
import 'package:vehnway/core/constants/app_gradients.dart';

class StartCard extends StatelessWidget {
  const StartCard({super.key});

  Future<void> _startDrive(BuildContext context) async {
    final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
    if (vehicleProvider.vehicleId == null) {
      CustomSnackBar.showWarning(
        context,
        "Please select or add a vehicle before starting your drive.",
      );
      return;
    }

    final orientation = MediaQuery.of(context).orientation;
    if (orientation == Orientation.portrait) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(Icons.screen_rotation_rounded, size: 34),
            title: const Text('Rotate your phone'),
            content: const Text(
              'Please hold your phone horizontally for the best drive experience before starting the drive.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );

      if (shouldContinue != true || !context.mounted) {
        return;
      }
    }

    if (!context.mounted) return;

    Navigator.pushNamed(
      context,
      "/loading",
      arguments: {
        "duration": const Duration(seconds: 3),
        "onComplete": () {
          Navigator.pushReplacementNamed(context, "/imu");
        },
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassLiteContainer(
      hasBorder: false,
      backgroundColor: AppColors.background,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _startDrive(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Text(
                'Start Drive',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, "/map-webview"),
            onLongPress: () => Navigator.pushNamed(context, "/map"),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.map, color: Colors.white70, size: 24),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
