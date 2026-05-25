import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vehnway/Providers/vehicle_provider.dart';
import 'package:vehnway/Widgets/custom_snackbar.dart';
import 'package:vehnway/Widgets/glass_lite_container.dart';
import 'package:vehnway/core/constants/app_gradients.dart';

class StartCard extends StatelessWidget {
  const StartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassLiteContainer(
      hasBorder: false,
      backgroundColor: AppColors.background,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              final vehicleProvider = Provider.of<VehicleProvider>(
                context,
                listen: false,
              );
              if (vehicleProvider.vehicleId == null) {
                CustomSnackBar.showWarning(
                  context,
                  "Please select or add a vehicle before starting your drive.",
                );
                return;
              }
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
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Text(
                'Start Drive',
                style: const TextStyle(
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
