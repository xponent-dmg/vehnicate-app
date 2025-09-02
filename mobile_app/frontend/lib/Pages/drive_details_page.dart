import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:vehnicate_frontend/models/drive_model.dart';

// Constants and Theme (consistent with other pages)
class DriveDetailsConstants {
  // Colors
  static const Color primaryBackground = Color(0xFF01010D);
  static const Color cardBackground = Color(0xFF0E0E1A);
  static const Color accentPurple = Color(0xFF765FD1);
  static const Color lightPurple = Color(0xFF9217BB);
  static const Color darkPurple = Color(0xFF403862);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningRed = Color(0xFFF24E1E);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color dividerColor = Color(0x33B0A4AD);

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w700,
  );

  static const TextStyle subtitleStyle = TextStyle(
    color: Colors.white70,
    fontSize: 14,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w500,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w600,
  );

  static const TextStyle metricValueStyle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w700,
  );

  static const TextStyle metricLabelStyle = TextStyle(
    color: Colors.white70,
    fontSize: 12,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w500,
  );

  static const TextStyle improvementStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontFamily: 'Manrope',
    fontWeight: FontWeight.w700,
  );

  // Dimensions
  static const double cardRadius = 12.0;
  static const double horizontalPadding = 24.0;
  static const double chartHeight = 200.0;
}

class DriveDetailsPage extends StatefulWidget {
  final Drive drive;

  const DriveDetailsPage({super.key, required this.drive});

  @override
  State<DriveDetailsPage> createState() => _DriveDetailsPageState();
}

class _DriveDetailsPageState extends State<DriveDetailsPage> {
  PageController _chartController = PageController();
  int _currentChartIndex = 0;

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriveDetailsConstants.primaryBackground,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(image: AssetImage("assets/bg-image.png"), fit: BoxFit.fitHeight),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Column(children: [_buildChartsSection(), SizedBox(height: 24), _buildSummaryCard()]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DriveDetailsConstants.horizontalPadding, vertical: 16),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.drive.carName, style: DriveDetailsConstants.titleStyle),
                    Text(_formatDate(widget.drive.date), style: DriveDetailsConstants.subtitleStyle),
                  ],
                ),
              ),
              _buildScoreDisplay(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay() {
    Color trendColor;
    IconData trendIcon;

    switch (widget.drive.scoreTrend) {
      case 'up':
        trendColor = DriveDetailsConstants.successGreen;
        trendIcon = FontAwesomeIcons.arrowTrendUp;
        break;
      case 'down':
        trendColor = DriveDetailsConstants.warningRed;
        trendIcon = FontAwesomeIcons.arrowTrendDown;
        break;
      default:
        trendColor = Colors.white70;
        trendIcon = FontAwesomeIcons.minus;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: DriveDetailsConstants.cardBackground, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${widget.drive.avgScore.toStringAsFixed(1)}', style: DriveDetailsConstants.metricValueStyle),
          SizedBox(width: 4),
          Icon(trendIcon, color: trendColor, size: 16),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      children: [
        // Chart indicators
        Padding(
          padding: EdgeInsets.symmetric(horizontal: DriveDetailsConstants.horizontalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentChartIndex == index ? DriveDetailsConstants.accentPurple : Colors.white30,
                ),
              );
            }),
          ),
        ),
        SizedBox(height: 16),

        // Swipeable charts
        SizedBox(
          height: DriveDetailsConstants.chartHeight + 60, // Extra space for title
          child: PageView(
            controller: _chartController,
            onPageChanged: (index) {
              setState(() {
                _currentChartIndex = index;
              });
            },
            children: [
              _buildChartCard(title: 'Score vs Time', chart: _buildScoreChart()),
              _buildChartCard(title: 'Speed vs Time', chart: _buildSpeedChart()),
              _buildChartCard(title: 'Harsh Events', chart: _buildEventsChart()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard({required String title, required Widget chart}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DriveDetailsConstants.horizontalPadding),
      child: Container(
        decoration: BoxDecoration(
          color: DriveDetailsConstants.cardBackground,
          borderRadius: BorderRadius.circular(DriveDetailsConstants.cardRadius),
          boxShadow: [
            BoxShadow(color: DriveDetailsConstants.lightPurple.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: DriveDetailsConstants.cardTitleStyle),
              SizedBox(height: 16),
              Expanded(child: chart),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}m', style: DriveDetailsConstants.metricLabelStyle);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}', style: DriveDetailsConstants.metricLabelStyle);
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: widget.drive.scorePoints.map((point) => FlSpot(point.time, point.score)).toList(),
            isCurved: true,
            color: DriveDetailsConstants.accentPurple,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: DriveDetailsConstants.lightPurple,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(show: true, color: DriveDetailsConstants.accentPurple.withOpacity(0.2)),
          ),
        ],
        minY: 0,
        maxY: 100,
      ),
    );
  }

  Widget _buildSpeedChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}m', style: DriveDetailsConstants.metricLabelStyle);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}', style: DriveDetailsConstants.metricLabelStyle);
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: widget.drive.speedPoints.map((point) => FlSpot(point.time, point.speed)).toList(),
            isCurved: true,
            color: DriveDetailsConstants.warningOrange,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: DriveDetailsConstants.warningOrange,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(show: true, color: DriveDetailsConstants.warningOrange.withOpacity(0.2)),
          ),
        ],
        minY: 0,
      ),
    );
  }

  Widget _buildEventsChart() {
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}m', style: DriveDetailsConstants.metricLabelStyle);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}', style: DriveDetailsConstants.metricLabelStyle);
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups:
            widget.drive.eventPoints.map((event) {
              return BarChartGroupData(
                x: event.time.toInt(),
                barRods: [
                  BarChartRodData(
                    toY: event.intensity,
                    color:
                        event.type == 'brake' ? DriveDetailsConstants.warningRed : DriveDetailsConstants.warningOrange,
                    width: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
        maxY: 10,
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DriveDetailsConstants.horizontalPadding),
      child: Container(
        decoration: BoxDecoration(
          color: DriveDetailsConstants.cardBackground,
          borderRadius: BorderRadius.circular(DriveDetailsConstants.cardRadius),
          boxShadow: [
            BoxShadow(color: DriveDetailsConstants.lightPurple.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Drive Summary', style: DriveDetailsConstants.cardTitleStyle),
              SizedBox(height: 16),

              // Improvement indicator
              _buildImprovementIndicator(),
              SizedBox(height: 20),

              // Metrics grid
              _buildMetricsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImprovementIndicator() {
    final isImprovement = widget.drive.improvementPercent > 0;
    final color = isImprovement ? DriveDetailsConstants.successGreen : DriveDetailsConstants.warningRed;
    final icon = isImprovement ? FontAwesomeIcons.arrowTrendUp : FontAwesomeIcons.arrowTrendDown;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isImprovement ? 'Improvement' : 'Needs Work',
                  style: DriveDetailsConstants.cardTitleStyle.copyWith(color: color),
                ),
                Text(
                  '${widget.drive.improvementPercent.abs().toStringAsFixed(1)}% ${isImprovement ? 'better' : 'worse'} than previous drive',
                  style: DriveDetailsConstants.metricLabelStyle,
                ),
              ],
            ),
          ),
          Text(
            '${isImprovement ? '+' : ''}${widget.drive.improvementPercent.toStringAsFixed(1)}%',
            style: DriveDetailsConstants.improvementStyle.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                icon: FontAwesomeIcons.clock,
                label: 'Duration',
                value: _formatDuration(widget.drive.duration),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMetricItem(
                icon: FontAwesomeIcons.road,
                label: 'Distance',
                value: '${widget.drive.distance.toStringAsFixed(1)} km',
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricItem(
                icon: FontAwesomeIcons.tachometerAlt,
                label: 'Avg Speed',
                value: '${widget.drive.avgSpeed.toStringAsFixed(1)} km/h',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMetricItem(
                icon: FontAwesomeIcons.exclamationTriangle,
                label: 'Harsh Events',
                value: '${widget.drive.harshBrakes + widget.drive.harshAccelerations}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricItem({required IconData icon, required String label, required String value}) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DriveDetailsConstants.darkPurple.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: DriveDetailsConstants.accentPurple, size: 16),
              SizedBox(width: 6),
              Text(label, style: DriveDetailsConstants.metricLabelStyle),
            ],
          ),
          SizedBox(height: 4),
          Text(value, style: DriveDetailsConstants.metricValueStyle),
        ],
      ),
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
