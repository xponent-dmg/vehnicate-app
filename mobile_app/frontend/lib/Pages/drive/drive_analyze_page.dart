import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:vehnway/Providers/vehicle_provider.dart';
import 'package:vehnway/models/drive_model.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vehnway/Widgets/star_refresh_indicator.dart';
import 'package:vehnway/core/constants/app_gradients.dart';
import 'package:vehnway/Widgets/drive_filter_sheet.dart';
import 'package:vehnway/Widgets/glass_lite_container.dart';

// Constants and Theme (consistent with ProfilePage)
class DriveAnalyzeConstants {
  // Colors
  // static const Color primaryBackground = Color(0xFF01010D);
  static const Color cardBackground = AppColors.background;
  static const Color accentPurple = AppColors.mutedPurple;
  static const Color lightPurple = AppColors.vividPurple;
  static const Color darkPurple = AppColors.deepPurpleAccent;
  static const Color dividerColor = Color(0x33B0A4AD);
  static const Color successGreen = AppColors.success;
  static const Color warningRed = AppColors.danger;

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle subtitleStyle = TextStyle(
    color: Colors.white70,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle carNameStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle dateStyle = TextStyle(
    color: Colors.white70,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle metricStyle = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle scoreStyle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  // Dimensions
  static const double cardRadius = 24;
  static const double horizontalPadding = 24.0;
}

class DriveAnalyzePage extends StatefulWidget {
  const DriveAnalyzePage({super.key});

  @override
  State<DriveAnalyzePage> createState() => DriveAnalyzePageState();
}

class DriveAnalyzePageState extends State<DriveAnalyzePage> {
  // Filter state
  int? _filterVehicleId;
  DateTime? _filterDate;
  RangeValues _filterDuration = const RangeValues(
    0,
    600,
  ); // 10 hours max default
  RangeValues _filterDistance = const RangeValues(0, 2000); // in km
  TimeOfDay? _filterStartTime;
  TimeOfDay? _filterEndTime;

  void showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DriveFilterSheet(
          initialVehicleId: _filterVehicleId,
          initialDate: _filterDate,
          initialDuration: _filterDuration,
          initialDistance: _filterDistance,
          initialStartTime: _filterStartTime,
          initialEndTime: _filterEndTime,
          onApply: ({vehicleId, date, duration, distance, startTime, endTime}) {
            setState(() {
              _filterVehicleId = vehicleId;
              _filterDate = date;
              _filterDuration = duration ?? _filterDuration;
              _filterDistance = distance ?? _filterDistance;
              _filterStartTime = startTime;
              _filterEndTime = endTime;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Consumer<VehicleProvider>(
                builder: (context, vehicleProvider, child) {
                  final rawDrives = vehicleProvider.drives;
                  final carName = vehicleProvider.vehicleModel ?? 'Unknown Car';

                  final drives =
                      rawDrives.where((drive) {
                        if (_filterVehicleId != null &&
                            drive.vehicleId != _filterVehicleId) {
                          return false;
                        }

                        if (_filterDate != null) {
                          if (drive.startTime.year != _filterDate!.year ||
                              drive.startTime.month != _filterDate!.month ||
                              drive.startTime.day != _filterDate!.day) {
                            return false;
                          }
                        }

                        final durationMins =
                            drive.duration.inMinutes.toDouble();
                        if (durationMins < _filterDuration.start ||
                            durationMins > _filterDuration.end) {
                          return false;
                        }

                        if (drive.distance < _filterDistance.start ||
                            drive.distance > _filterDistance.end) {
                          return false;
                        }

                        if (_filterStartTime != null) {
                          if (drive.startTime.hour < _filterStartTime!.hour ||
                              (drive.startTime.hour == _filterStartTime!.hour &&
                                  drive.startTime.minute <
                                      _filterStartTime!.minute)) {
                            return false;
                          }
                        }

                        if (_filterEndTime != null) {
                          if (drive.endTime.hour > _filterEndTime!.hour ||
                              (drive.endTime.hour == _filterEndTime!.hour &&
                                  drive.endTime.minute >
                                      _filterEndTime!.minute)) {
                            return false;
                          }
                        }

                        return true;
                      }).toList();

                  return StarRefreshIndicator(
                    onRefresh: () async {
                      await vehicleProvider.loadDrives();
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 10,
                      ),
                      itemCount:
                          vehicleProvider.isLoading && rawDrives.isEmpty
                              ? 4
                              : drives.length,
                      itemBuilder: (context, index) {
                        if (vehicleProvider.isLoading && rawDrives.isEmpty) {
                          return _buildShimmerCard(context);
                        }

                        if (index >= drives.length) {
                          return const SizedBox.shrink();
                        }

                        final drive = drives[index];
                        return _buildDriveCard(context, drive, carName);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    return GlassLiteContainer(
      margin: const EdgeInsets.only(bottom: 20),
      height: 130,
      backgroundColor: AppColors.darkGreyBackground,
      borderRadius: BorderRadius.circular(24),
      child: Shimmer.fromColors(
        baseColor: ShimmerConstants.shimmerBase,
        highlightColor: ShimmerConstants.shimmerHighlight,
        direction: ShimmerDirection.ttb,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 10, color: AppColors.primary),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 48.0,
                  top: 20.0,
                  right: 60.0,
                  bottom: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 18,
                      decoration: BoxDecoration(
                        color: ShimmerConstants.shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 140,
                      height: 14,
                      decoration: BoxDecoration(
                        color: ShimmerConstants.shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 18,
                          decoration: BoxDecoration(
                            color: ShimmerConstants.shimmerBase,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 60,
                          height: 18,
                          decoration: BoxDecoration(
                            color: ShimmerConstants.shimmerBase,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 25,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(
                    Icons.arrow_right_rounded,
                    color: Colors.grey[500],
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriveCard(BuildContext context, Drive drive, String carName) {
    final duration = drive.endTime.difference(drive.startTime);

    return GlassLiteContainer(
      margin: const EdgeInsets.only(bottom: 20),
      height: 130,
      backgroundColor: AppColors.darkGreyBackground,
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.pushNamed(context, "/drive-details", arguments: drive);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 8, color: AppColors.primary),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 48.0,
                top: 22,
                right: 60.0,
                bottom: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    carName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(drive.startTime),
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildMetric(
                        icon: FontAwesomeIcons.road,
                        value: '${drive.distance.toStringAsFixed(1)} km',
                      ),
                      const SizedBox(width: 16),
                      _buildMetric(
                        icon: FontAwesomeIcons.clock,
                        value: _formatDuration(duration),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 25,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(
                  Icons.arrow_right_rounded,
                  color: Colors.grey[500],
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric({required IconData icon, required String value}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey[400], size: 14),
        const SizedBox(width: 6),
        Text(value, style: DriveAnalyzeConstants.metricStyle),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
