import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vehnicate_frontend/models/drive_model.dart';
import 'package:vehnicate_frontend/Pages/drive_details_page.dart';

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

  // Dummy data for drives
  static final List<Drive> _dummyDrives = [
    Drive(
      id: '1',
      carName: 'Tesla Model 3',
      date: DateTime(2024, 8, 28),
      distance: 15.3,
      avgScore: 87.5,
      scoreTrend: 'up',
      duration: Duration(minutes: 32),
      improvementPercent: 12.5,
      harshBrakes: 2,
      harshAccelerations: 1,
      avgSpeed: 28.7,
      scorePoints: [
        ScorePoint(time: 0, score: 85),
        ScorePoint(time: 5, score: 88),
        ScorePoint(time: 10, score: 86),
        ScorePoint(time: 15, score: 90),
        ScorePoint(time: 20, score: 87),
        ScorePoint(time: 25, score: 89),
        ScorePoint(time: 30, score: 88),
      ],
      speedPoints: [
        SpeedPoint(time: 0, speed: 0),
        SpeedPoint(time: 5, speed: 35),
        SpeedPoint(time: 10, speed: 42),
        SpeedPoint(time: 15, speed: 25),
        SpeedPoint(time: 20, speed: 38),
        SpeedPoint(time: 25, speed: 30),
        SpeedPoint(time: 30, speed: 15),
      ],
      eventPoints: [
        EventPoint(time: 8, type: 'brake', intensity: 7.2),
        EventPoint(time: 18, type: 'acceleration', intensity: 6.8),
        EventPoint(time: 24, type: 'brake', intensity: 8.1),
      ],
    ),
    Drive(
      id: '2',
      carName: 'Honda Civic',
      date: DateTime(2024, 8, 26),
      distance: 22.1,
      avgScore: 72.8,
      scoreTrend: 'down',
      duration: Duration(minutes: 45),
      improvementPercent: -8.3,
      harshBrakes: 5,
      harshAccelerations: 3,
      avgSpeed: 29.5,
      scorePoints: [
        ScorePoint(time: 0, score: 78),
        ScorePoint(time: 10, score: 75),
        ScorePoint(time: 20, score: 70),
        ScorePoint(time: 30, score: 68),
        ScorePoint(time: 40, score: 72),
      ],
      speedPoints: [
        SpeedPoint(time: 0, speed: 0),
        SpeedPoint(time: 10, speed: 40),
        SpeedPoint(time: 20, speed: 32),
        SpeedPoint(time: 30, speed: 45),
        SpeedPoint(time: 40, speed: 20),
      ],
      eventPoints: [
        EventPoint(time: 5, type: 'acceleration', intensity: 8.5),
        EventPoint(time: 12, type: 'brake', intensity: 9.1),
        EventPoint(time: 18, type: 'brake', intensity: 7.8),
        EventPoint(time: 25, type: 'acceleration', intensity: 8.2),
        EventPoint(time: 32, type: 'brake', intensity: 8.9),
        EventPoint(time: 38, type: 'acceleration', intensity: 7.5),
        EventPoint(time: 42, type: 'brake', intensity: 8.3),
      ],
    ),
    Drive(
      id: '3',
      carName: 'BMW X5',
      date: DateTime(2024, 8, 24),
      distance: 8.7,
      avgScore: 91.2,
      scoreTrend: 'up',
      duration: Duration(minutes: 18),
      improvementPercent: 15.7,
      harshBrakes: 0,
      harshAccelerations: 1,
      avgSpeed: 29.0,
      scorePoints: [
        ScorePoint(time: 0, score: 89),
        ScorePoint(time: 5, score: 92),
        ScorePoint(time: 10, score: 90),
        ScorePoint(time: 15, score: 93),
      ],
      speedPoints: [
        SpeedPoint(time: 0, speed: 0),
        SpeedPoint(time: 5, speed: 30),
        SpeedPoint(time: 10, speed: 35),
        SpeedPoint(time: 15, speed: 25),
      ],
      eventPoints: [EventPoint(time: 12, type: 'acceleration', intensity: 6.2)],
    ),
    Drive(
      id: '4',
      carName: 'Toyota Camry',
      date: DateTime(2024, 8, 22),
      distance: 34.5,
      avgScore: 79.3,
      scoreTrend: 'stable',
      duration: Duration(minutes: 65),
      improvementPercent: 2.1,
      harshBrakes: 3,
      harshAccelerations: 2,
      avgSpeed: 31.8,
      scorePoints: [
        ScorePoint(time: 0, score: 80),
        ScorePoint(time: 15, score: 78),
        ScorePoint(time: 30, score: 81),
        ScorePoint(time: 45, score: 77),
        ScorePoint(time: 60, score: 80),
      ],
      speedPoints: [
        SpeedPoint(time: 0, speed: 0),
        SpeedPoint(time: 15, speed: 35),
        SpeedPoint(time: 30, speed: 40),
        SpeedPoint(time: 45, speed: 28),
        SpeedPoint(time: 60, speed: 15),
      ],
      eventPoints: [
        EventPoint(time: 10, type: 'brake', intensity: 7.5),
        EventPoint(time: 22, type: 'acceleration', intensity: 7.8),
        EventPoint(time: 35, type: 'brake', intensity: 8.0),
        EventPoint(time: 48, type: 'acceleration', intensity: 7.2),
        EventPoint(time: 55, type: 'brake', intensity: 7.9),
      ],
    ),
    Drive(
      id: '5',
      carName: 'Audi A4',
      date: DateTime(2024, 8, 20),
      distance: 12.8,
      avgScore: 84.6,
      scoreTrend: 'up',
      duration: Duration(minutes: 28),
      improvementPercent: 9.4,
      harshBrakes: 1,
      harshAccelerations: 2,
      avgSpeed: 27.4,
      scorePoints: [
        ScorePoint(time: 0, score: 82),
        ScorePoint(time: 7, score: 85),
        ScorePoint(time: 14, score: 83),
        ScorePoint(time: 21, score: 87),
        ScorePoint(time: 28, score: 85),
      ],
      speedPoints: [
        SpeedPoint(time: 0, speed: 0),
        SpeedPoint(time: 7, speed: 32),
        SpeedPoint(time: 14, speed: 38),
        SpeedPoint(time: 21, speed: 25),
        SpeedPoint(time: 28, speed: 10),
      ],
      eventPoints: [
        EventPoint(time: 9, type: 'acceleration', intensity: 7.1),
        EventPoint(time: 16, type: 'brake', intensity: 7.6),
        EventPoint(time: 23, type: 'acceleration', intensity: 6.9),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriveAnalyzeConstants.primaryBackground,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(image: AssetImage("assets/bg-image.png"), fit: BoxFit.fitHeight),
          ),
          child: Column(children: [_buildHeader(context), Expanded(child: _buildDrivesList())]),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DriveAnalyzeConstants.horizontalPadding, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              ),
              SizedBox(width: 8),
              Text('Drive Analysis', style: DriveAnalyzeConstants.titleStyle),
            ],
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Text('Review your past drives and track your progress', style: DriveAnalyzeConstants.subtitleStyle),
          ),
        ],
      ),
    );
  }

  Widget _buildDrivesList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: DriveAnalyzeConstants.horizontalPadding),
      itemCount: _dummyDrives.length,
      itemBuilder: (context, index) {
        final drive = _dummyDrives[index];
        return Padding(padding: EdgeInsets.only(bottom: 12), child: _buildDriveCard(context, drive));
      },
    );
  }

  Widget _buildDriveCard(BuildContext context, Drive drive) {
    return Container(
      decoration: BoxDecoration(
        color: DriveAnalyzeConstants.cardBackground,
        borderRadius: BorderRadius.circular(DriveAnalyzeConstants.cardRadius),
        boxShadow: [
          BoxShadow(color: DriveAnalyzeConstants.lightPurple.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => DriveDetailsPage(drive: drive)));
        },
        leading: _buildCarIcon(drive.carName),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(drive.carName, style: DriveAnalyzeConstants.carNameStyle),
            SizedBox(height: 4),
            Text(_formatDate(drive.date), style: DriveAnalyzeConstants.dateStyle),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 8),
          child: Row(
            children: [
              _buildMetric(icon: FontAwesomeIcons.road, value: '${drive.distance.toStringAsFixed(1)} km'),
              SizedBox(width: 16),
              _buildMetric(icon: FontAwesomeIcons.clock, value: _formatDuration(drive.duration)),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildScoreDisplay(drive.avgScore, drive.scoreTrend),
            SizedBox(height: 4),
            Icon(Icons.arrow_forward_ios, color: DriveAnalyzeConstants.accentPurple, size: 16),
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
      decoration: BoxDecoration(color: DriveAnalyzeConstants.darkPurple, borderRadius: BorderRadius.circular(12)),
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
        Text('${score.toStringAsFixed(1)}', style: DriveAnalyzeConstants.scoreStyle),
        SizedBox(width: 4),
        Icon(trendIcon, color: trendColor, size: 14),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
