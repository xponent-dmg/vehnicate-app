import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vehnicate_frontend/Widgets/line_chart_widget.dart';

class AccelerometerGraph extends StatefulWidget {
  const AccelerometerGraph({super.key});

  @override
  State<AccelerometerGraph> createState() => _AccelerometerGraphState();
}

class _AccelerometerGraphState extends State<AccelerometerGraph> {
  List<FlSpot> _xPoints = [FlSpot(0, 0)];
  List<FlSpot> _yPoints = [FlSpot(0, 0)];
  List<FlSpot> _zPoints = [FlSpot(0, 0)];
  int time = 0;
  late StreamSubscription<UserAccelerometerEvent>? _sub;

  bool isRunning = false;

  void startStream() {
    _sub = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      setState(() {
        //if you want to see the points dynamically, just last 50 points

        /*
        if (_xPoints.length > 50) {
          _xPoints.removeAt(0);
          _yPoints.removeAt(0);
          _zPoints.removeAt(0);
        }
        */
        _xPoints.add(FlSpot(time.toDouble(), event.x));
        _yPoints.add(FlSpot(time.toDouble(), event.y));
        _zPoints.add(FlSpot(time.toDouble(), event.z));
        time++;
        isRunning = true;
      });
    });
  }

  void stopStream() {
    _sub?.cancel();
    _sub = null;
    isRunning = false;
  }

  void togglePlayPause() {
    (isRunning) ? stopStream() : startStream();
  }

  void cleardata() {
    stopStream();
    setState(() {
      _xPoints.clear();
      _yPoints.clear();
      _zPoints.clear();
      time = 0;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Accelerometer Chart"),
        actions: [
          IconButton(
            icon: Icon(isRunning ? Icons.pause : Icons.play_arrow_rounded),
            onPressed: () => togglePlayPause(),
          ),
          IconButton(onPressed: () => cleardata(), icon: Icon(Icons.delete)),
          SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Text("X Axis"),
            SizedBox(
              height: 200,
              child: LineChartWidget(dataPoints: _xPoints, color: Colors.red),
            ),
            const Text("Y Axis"),
            SizedBox(
              height: 200,
              child: LineChartWidget(dataPoints: _yPoints, color: Colors.green),
            ),
            const Text("Z Axis"),
            SizedBox(
              height: 200,
              child: LineChartWidget(dataPoints: _zPoints, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
