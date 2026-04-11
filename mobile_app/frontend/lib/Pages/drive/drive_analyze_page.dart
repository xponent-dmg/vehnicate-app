import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';
import 'package:vehnicate_frontend/models/drive_model.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vehnicate_frontend/Widgets/star_refresh_indicator.dart';
import 'package:vehnicate_frontend/core/constants/app_gradients.dart';
import 'package:vehnicate_frontend/Widgets/drive_filter_sheet.dart';

// Constants and Theme (consistent with ProfilePage)
class DriveAnalyzeConstants {
  // Colors
  // static const Color primaryBackground = Color(0xFF01010D);
  static const Color cardBackground = Color(0xFF2d2d44);
  static const Color accentPurple = Color(0xFF765FD1);
  static const Color lightPurple = Color(0xFF9217BB);
  static const Color darkPurple = Color(0xFF403862);
  static const Color dividerColor = Color(0x33B0A4AD);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningRed = Color(0xFFF24E1E);

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
  RangeValues _filterDuration = const RangeValues(0, 600); // 10 hours max default
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
          onApply: ({
            vehicleId,
            date,
            duration,
            distance,
            startTime,
            endTime,
          }) {
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
                      itemCount:
                          vehicleProvider.isLoading && rawDrives.isEmpty
                              ? 4
                              : drives.length,
                      itemBuilder: (context, index) {
                        if (vehicleProvider.isLoading && rawDrives.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal:
                                  DriveAnalyzeConstants.horizontalPadding,
                              vertical: 8,
                            ),
                            child: _buildShimmerCard(context),
                          );
                        }

                        if (index >= drives.length) {
                          return const SizedBox.shrink();
                        }

                        final drive = drives[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DriveAnalyzeConstants.horizontalPadding,
                            vertical: 8,
                          ),
                          child: _buildDriveCard(context, drive, carName),
                        );
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DriveAnalyzeConstants.cardRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (DriveAnalyzeConstants.cardBackground),
            (DriveAnalyzeConstants.cardBackground).withOpacity(0.2),
          ],
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: ShimmerConstants.shimmerBase,
        highlightColor: ShimmerConstants.shimmerHighlight,
        direction: ShimmerDirection.ttb,
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 128,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Leading icon box
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ShimmerConstants.shimmerBase,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              // Title + subtitle column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 18,
                      decoration: BoxDecoration(
                        color: ShimmerConstants.shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 140,
                      height: 16,
                      decoration: BoxDecoration(
                        color: ShimmerConstants.shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 20,
                          decoration: BoxDecoration(
                            color: ShimmerConstants.shimmerBase,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 60,
                          height: 20,
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
              const Icon(
                Icons.arrow_right_rounded,
                color: Colors.white,
                size: 35,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriveCard(BuildContext context, Drive drive, String carName) {
    final duration = drive.endTime.difference(drive.startTime);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DriveAnalyzeConstants.cardRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (DriveAnalyzeConstants.cardBackground),
            (DriveAnalyzeConstants.cardBackground).withOpacity(0.2),
          ],
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () {
          Navigator.pushNamed(context, "/drive-details", arguments: drive);
        },
        leading: _buildCarIcon(carName, context),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(carName, style: DriveAnalyzeConstants.carNameStyle),
            const SizedBox(height: 4),
            Text(
              _formatDate(drive.startTime),
              style: DriveAnalyzeConstants.dateStyle,
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
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
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(
              Icons.arrow_right_rounded,
              color: Theme.of(context).primaryColor,
              size: 35,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarIcon(String carName, BuildContext context) {
    IconData icon;
    if (carName.toLowerCase().contains('tesla')) {
      icon = FontAwesomeIcons.bolt;
    } else if (carName.toLowerCase().contains('bmw')) {
      icon = FontAwesomeIcons.car;
    } else if (carName.toLowerCase().contains('audi')) {
      icon = FontAwesomeIcons.carSide;
    } else {
      icon = FontAwesomeIcons.car;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha(70),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
    );
  }

  Widget _buildMetric({required IconData icon, required String value}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
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
