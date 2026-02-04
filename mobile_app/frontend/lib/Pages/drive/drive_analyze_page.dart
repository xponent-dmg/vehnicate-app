import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';
import 'package:vehnicate_frontend/Widgets/header.dart';
import 'package:vehnicate_frontend/models/drive_model.dart';
import 'package:intl/intl.dart';

// Constants and Theme (consistent with ProfilePage)
class DriveAnalyzeConstants {
  // Colors
  static const Color primaryBackground = Color(0xFF01010D);
  static const Color cardBackground = Color(0xFF0E0E1A);
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
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w700,
  );

  static const TextStyle subtitleStyle = TextStyle(
    color: Colors.white70,
    fontSize: 16,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w500,
  );

  static const TextStyle carNameStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w600,
  );

  static const TextStyle dateStyle = TextStyle(
    color: Colors.white70,
    fontSize: 12,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w500,
  );

  static const TextStyle metricStyle = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w500,
  );

  static const TextStyle scoreStyle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w700,
  );

  // Dimensions
  static const double cardRadius = 12.0;
  static const double horizontalPadding = 24.0;
}

class DriveAnalyzePage extends StatelessWidget {
  const DriveAnalyzePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Consumer<VehicleProvider>(
          builder: (context, vehicleProvider, child) {
            final drives = vehicleProvider.drives;
            return RefreshIndicator(
              onRefresh: () async {
                await vehicleProvider.loadDrives();
              },
              color: DriveAnalyzeConstants.accentPurple,
              backgroundColor: DriveAnalyzeConstants.cardBackground,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: drives.length,
                itemBuilder: (context, index) {
                  final drive = drives[index];
                  // We can pass the car name from the provider, as all drives are for this vehicle
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: DriveAnalyzeConstants.horizontalPadding,
                      vertical: 6,
                    ),
                    child: _buildDriveCard(
                      context,
                      drive,
                      vehicleProvider.vehicleModel ?? 'Unknown Car',
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDriveCard(BuildContext context, Drive drive, String carName) {
    final duration = drive.endTime.difference(drive.startTime);

    return Container(
      decoration: BoxDecoration(
        color: DriveAnalyzeConstants.cardBackground,
        borderRadius: BorderRadius.circular(DriveAnalyzeConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: DriveAnalyzeConstants.lightPurple.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        onTap: () {
          Navigator.pushNamed(context, "/drive-details", arguments: drive);
        },
        leading: _buildCarIcon(carName),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(carName, style: DriveAnalyzeConstants.carNameStyle),
            SizedBox(height: 4),
            Text(
              _formatDate(drive.startTime),
              style: DriveAnalyzeConstants.dateStyle,
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 8),
          child: Row(
            children: [
              _buildMetric(
                icon: FontAwesomeIcons.road,
                value: '${drive.distance.toStringAsFixed(1)} km',
              ),
              SizedBox(width: 16),
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
            // Score handling removed for now as per new schema
            // _buildScoreDisplay(drive.avgScore, drive.scoreTrend),
            // SizedBox(height: 4),
            Icon(
              Icons.arrow_forward_ios,
              color: DriveAnalyzeConstants.accentPurple,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarIcon(String carName) {
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
        color: DriveAnalyzeConstants.darkPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: DriveAnalyzeConstants.accentPurple, size: 24),
    );
  }

  Widget _buildMetric({required IconData icon, required String value}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        SizedBox(width: 4),
        Text(value, style: DriveAnalyzeConstants.metricStyle),
      ],
    );
  }

  /*
  Widget _buildScoreDisplay(double score, String trend) {
    Color trendColor;
    IconData trendIcon;

    switch (trend) {
      case 'up':
        trendColor = DriveAnalyzeConstants.successGreen;
        trendIcon = FontAwesomeIcons.arrowTrendUp;
        break;
      case 'down':
        trendColor = DriveAnalyzeConstants.warningRed;
        trendIcon = FontAwesomeIcons.arrowTrendDown;
        break;
      default:
        trendColor = Colors.white70;
        trendIcon = FontAwesomeIcons.minus;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(score.toStringAsFixed(1), style: DriveAnalyzeConstants.scoreStyle),
        SizedBox(width: 4),
        Icon(trendIcon, color: trendColor, size: 14),
      ],
    );
  }
  */

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
