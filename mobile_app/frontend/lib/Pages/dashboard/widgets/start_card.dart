import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:vehnway/Providers/vehicle_provider.dart';
import 'package:vehnway/Widgets/custom_snackbar.dart';
import 'package:vehnway/Widgets/glass_lite_container.dart';
import 'package:vehnway/core/constants/app_gradients.dart';

class StartCard extends StatelessWidget {
  const StartCard({super.key});

  Future<bool?> _chooseCameraMode(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Start drive'),
          content: const Text('Would you like to use the camera for this drive?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Without camera'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('With camera'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _requestDrivePermissions(
    BuildContext context, {
    required bool useCamera,
  }) async {
    final locationStatus = await Permission.location.request();
    if (!locationStatus.isGranted && !locationStatus.isLimited) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Location permission is required to start a drive.');
      }
      return false;
    }

    if (useCamera) {
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted && !cameraStatus.isLimited) {
        if (context.mounted) {
          CustomSnackBar.showError(context, 'Camera permission is required for this drive.');
        }
        return false;
      }
    }

    return true;
  }

  Future<void> _showLandscapeTransition(BuildContext context) async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (!context.mounted) return;

    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          builder: (context, value, child) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.rotate(
                    angle: value * 1.5708,
                    child: const Icon(Icons.screen_rotation_rounded, size: 54),
                  ),
                  const SizedBox(height: 16),
                  const Text('Switching to horizontal view'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _startDrive(BuildContext context) async {
    final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
    if (vehicleProvider.vehicleId == null) {
      CustomSnackBar.showWarning(
        context,
        "Please select or add a vehicle before starting your drive.",
      );
      return;
    }

    final useCamera = await _chooseCameraMode(context);
    if (useCamera == null || !context.mounted) {
      return;
    }

    if (!await _requestDrivePermissions(context, useCamera: useCamera) ||
        !context.mounted) {
      return;
    }

    if (useCamera) {
      await _showLandscapeTransition(context);
      if (!context.mounted) {
        return;
      }
    }

    Navigator.pushNamed(
      context,
      "/loading",
      arguments: {
        "duration": const Duration(seconds: 3),
        "onComplete": () {
          Navigator.pushReplacementNamed(
            context,
            "/imu",
            arguments: useCamera,
          );
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
