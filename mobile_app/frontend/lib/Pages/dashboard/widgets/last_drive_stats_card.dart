import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vehnway/Providers/vehicle_provider.dart';
import 'package:vehnway/Widgets/glass_lite_container.dart';
import 'package:vehnway/core/constants/app_gradients.dart';

class LastDriveStatsCard extends StatelessWidget {
  const LastDriveStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final latestDrive = vehicleProvider.latestDrive;

    if (vehicleProvider.isLoading) {
      return GlassLiteContainer(
        hasBorder: false,
        backgroundColor: AppColors.background,
        padding: const EdgeInsets.all(20),
        child: const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    if (latestDrive == null) {
      return GlassLiteContainer(
        hasBorder: false,
        backgroundColor: AppColors.background,
        padding: const EdgeInsets.all(20),
        child: const SizedBox(
          height: 120,
          child: Center(
            child: Text(
              "No drives recorded yet. Start a drive to see your stats!",
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final liquidEllar = latestDrive.liquidEllar;
    final frozenEllar = latestDrive.frozenEllar;
    final roadDefects = latestDrive.roadDefects;
    final distance = latestDrive.distance;
    final duration = latestDrive.duration;

    final formattedDate = DateFormat(
      'MMM dd, yyyy • hh:mm a',
    ).format(latestDrive.startTime.toLocal());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final formattedDuration =
        hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return GlassLiteContainer(
      hasBorder: false,
      backgroundColor: AppColors.background,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Last Drive",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  formattedDuration,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formattedDate,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _NewStatItem(
                  label: "Liq Ellar",
                  value: liquidEllar.toString(),
                  icon: Icons.water_drop,
                  iconColor: const Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NewStatItem(
                  label: "Frozen Ellar",
                  value: frozenEllar.toString(),
                  icon: Icons.ac_unit,
                  iconColor: const Color(0xFFFFB0B0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NewStatItem(
                  label: "Defects",
                  value: roadDefects.toString(),
                  icon: Icons.warning_amber_rounded,
                  iconColor: const Color(0xFFFBBF24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NewStatItem(
                  label: "Distance",
                  value: "${distance.toStringAsFixed(1)} km",
                  icon: Icons.directions_run_rounded,
                  iconColor: const Color(0xFF34D399),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewStatItem extends StatelessWidget {
  const _NewStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
