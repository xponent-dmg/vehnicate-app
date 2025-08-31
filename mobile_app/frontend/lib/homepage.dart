import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  double x = 0.0, y = 0.0, z = 0.0;
  @override
  void initState() {
    super.initState();
    userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      setState(() {
        x = event.x;
        y = event.y;
        z = event.z;
        print("x : $x, y : $y, z : $z");
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Accelerometer Test")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("X: ${x.toStringAsFixed(2)}"),
            Text("Y: ${y.toStringAsFixed(2)}"),
            Text("Z: ${z.toStringAsFixed(2)}"),
          ],
        ),
      ),
    );
  }
}
