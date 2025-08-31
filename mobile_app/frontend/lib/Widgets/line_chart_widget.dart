import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LineChartWidget extends StatelessWidget {
  final Color color;
  final List<FlSpot> dataPoints;
  const LineChartWidget({super.key, required this.color, required this.dataPoints});

  double getMaxPoint(List<FlSpot> points) {
    if (points.isEmpty) return 5;
    final maxAbs = points.map((pair) => pair.y.abs()).reduce((a, b) => a > b ? a : b);
    return (maxAbs < 5) ? 5 : maxAbs;
  }

  @override
  Widget build(BuildContext context) {
    double maxAbs = getMaxPoint(dataPoints);
    return LineChart(
      LineChartData(
        clipData: FlClipData.all(),
        minY: -maxAbs,
        maxY: maxAbs,
        titlesData: FlTitlesData(show: true),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [LineChartBarData(spots: dataPoints, color: color, barWidth: 2, dotData: FlDotData(show: false))],
      ),
    );
  }
}
