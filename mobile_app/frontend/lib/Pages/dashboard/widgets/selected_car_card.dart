import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vehnway/Providers/vehicle_provider.dart';
import 'package:vehnway/Widgets/glass_lite_container.dart';
import 'package:vehnway/core/constants/app_gradients.dart';

class SelectedCarCard extends StatelessWidget {
  const SelectedCarCard({
    super.key,
    required this.onSwap,
    required this.onAddVehicle,
  });

  final VoidCallback onSwap;
  final VoidCallback onAddVehicle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Consumer<VehicleProvider>(
        builder: (context, vehicleProvider, child) {
          // shimmer while loading
          if (vehicleProvider.isLoading) {
            return const _CarCardShimmer();
          }

          final hasVehicle = vehicleProvider.vehicleId != null;

          return GlassLiteContainer(
            hasBorder: false,
            height: 160,
            backgroundColor: AppColors.background,
            padding: const EdgeInsets.all(17),
            child: hasVehicle
                // ── vehicle exists ──────────────────────────────────
                ? _VehicleInfoContent(
                    model: vehicleProvider.vehicleModel ?? 'No vehicle',
                    registration:
                        vehicleProvider.selectedVehicle?.formattedRegistration ??
                            '------',
                    onSwap: onSwap,
                  )
                // ── no vehicle yet ──────────────────────────────────
                : _NoVehicleContent(
                    onAddVehicle: onAddVehicle,
                  ),
          );
        },
      ),
    );
  }
}

/// Content shown when a vehicle IS selected.
class _VehicleInfoContent extends StatelessWidget {
  const _VehicleInfoContent({
    required this.model,
    required this.registration,
    required this.onSwap,
  });

  final String model;
  final String registration;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    registration,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onSwap,
              child: const Column(
                children: [
                  Icon(Icons.swap_horiz_rounded, color: Colors.white),
                  Text(
                    'Swap',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Image.asset("assets/images/vehicle_def.png")),
          ),
        ),
      ],
    );
  }
}

/// Content shown when NO vehicle has been added yet.
class _NoVehicleContent extends StatelessWidget {
  const _NoVehicleContent({required this.onAddVehicle});

  final VoidCallback onAddVehicle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onAddVehicle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(51),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Add Vehicle',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tap to add your vehicle',
          style: TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Skeleton for the selected-car card shown while VehicleProvider is loading.
class _CarCardShimmer extends StatelessWidget {
  const _CarCardShimmer();

  @override
  Widget build(BuildContext context) {
    return GlassLiteContainer(
      hasBorder: false,
      height: 160,
      backgroundColor: AppColors.background,
      padding: const EdgeInsets.all(17),
      child: Shimmer.fromColors(
        baseColor: ShimmerConstants.shimmerBase,
        highlightColor: ShimmerConstants.shimmerHighlight,
        direction: ShimmerDirection.ttb,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // mirrors Row(text column + swap icon)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // model name — fontSize:16 bold ≈ 18px
                      Container(
                        height: 18,
                        width: 100,
                        decoration: BoxDecoration(
                          color: ShimmerConstants.shimmerBase,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // registration — fontSize:11 ≈ 13px
                      Container(
                        height: 13,
                        width: 70,
                        decoration: BoxDecoration(
                          color: ShimmerConstants.shimmerBase,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
                // swap icon + label placeholder
                const Column(
                  children: [
                    Icon(Icons.swap_horiz_rounded, color: Colors.white),
                    Text(
                      'Swap',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // vehicle image placeholder
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: ShimmerConstants.shimmerBase,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
