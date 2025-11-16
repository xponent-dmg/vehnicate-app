import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:motion_sensors/motion_sensors.dart';
import 'package:vector_math/vector_math_64.dart';



class OrientationDetection2 extends StatefulWidget {
  const OrientationDetection2({super.key});

  @override
  State<OrientationDetection2> createState() => _OrientationDetection2State();
}

class _OrientationDetection2State extends State<OrientationDetection2> {
  final service = VehicleOrientationService();
  VehicleOrientation? data;
  StreamSubscription<VehicleOrientation>? _uiSub;

  @override
  void initState() {
    super.initState();
    service.start();
    _uiSub = service.vehicleOrientationStream.listen((value) {
      setState(() => data = value);
    });
  }

  @override
  void dispose() {
    _uiSub?.cancel();
    service.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Vehicle Orientation")),
        body: Center(
          child: data == null
              ? const Text("Waiting for sensor data…")
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Roll  : ${data!.roll.toStringAsFixed(2)}°"),
                    Text("Pitch : ${data!.pitch.toStringAsFixed(2)}°"),
                    Text("Yaw   : ${data!.yaw.toStringAsFixed(2)}°"),
                    const SizedBox(height: 20),
                    const Text("Rotation Matrix (phone → vehicle):"),
                    Text(data!.rotationMatrix.toString()),
                  ],
                ),
        ),
    );
  }
}



class VehicleOrientationService {
  // Streams
  final _vehicleOrientationController = StreamController<VehicleOrientation>.broadcast();
  Stream<VehicleOrientation> get vehicleOrientationStream => _vehicleOrientationController.stream;

  StreamSubscription? _orientationSub;

  // -------------------------
  // Mounting orientation
  // -------------------------
  // Assuming phone is held vertically on dashboard:
  // Phone X → Vehicle Y
  // Phone Y → Vehicle Z
  // Phone Z → Vehicle X
  //
  // This becomes a fixed matrix:
  //
  // [ 0  0  1 ]   Phone Z -> Vehicle X
  // [ 1  0  0 ]   Phone X -> Vehicle Y
  // [ 0  1  0 ]   Phone Y -> Vehicle Z
  //
  final Matrix3 R_mount = Matrix3(
    0, 0, 1,
    1, 0, 0,
    0, 1, 0,
  );

  void start() {
    // 50ms update interval (in microseconds, per motion_sensors API)
    motionSensors.absoluteOrientationUpdateInterval = 50000;

    _orientationSub = motionSensors.absoluteOrientation.listen((event) {
      // motion_sensors AbsoluteOrientationEvent provides yaw, pitch, roll in radians
      // Build phone-frame rotation matrix using Z-Y-X (yaw-pitch-roll) convention
      final Matrix3 R_phone = _eulerToMatrix(event.roll, event.pitch, event.yaw);

      // Convert phone → vehicle frame
      final Matrix3 R_vehicle = R_mount * R_phone;

      // Convert to roll, pitch, yaw (degrees) in the vehicle frame
      final angles = _matrixToEuler(R_vehicle);

      // Add to stream
      _vehicleOrientationController.add(
        VehicleOrientation(
          roll: angles.roll,
          pitch: angles.pitch,
          yaw: angles.yaw,
          rotationMatrix: R_vehicle,
        ),
      );
    });
  }

  void stop() {
    _orientationSub?.cancel();
    _vehicleOrientationController.close();
  }

  // ----------------------------------------------------------
  // Euler (roll, pitch, yaw in radians, X-Y-Z) → Matrix3 using R = Rz(yaw) * Ry(pitch) * Rx(roll)
  // ----------------------------------------------------------
  Matrix3 _eulerToMatrix(double roll, double pitch, double yaw) {
    final cr = cos(roll);
    final sr = sin(roll);
    final cp = cos(pitch);
    final sp = sin(pitch);
    final cy = cos(yaw);
    final sy = sin(yaw);  

    // Row-major elements
    final m00 = cy * cp;
    final m01 = cy * sp * sr - sy * cr;
    final m02 = cy * sp * cr + sy * sr;

    final m10 = sy * cp;
    final m11 = sy * sp * sr + cy * cr;
    final m12 = sy * sp * cr - cy * sr;

    final m20 = -sp;
    final m21 = cp * sr;
    final m22 = cp * cr;

    final m = Matrix3.zero();
    // Matrix3 stores values in column-major order
    m.setEntry(0, 0, m00); m.setEntry(0, 1, m01); m.setEntry(0, 2, m02);
    m.setEntry(1, 0, m10); m.setEntry(1, 1, m11); m.setEntry(1, 2, m12);
    m.setEntry(2, 0, m20); m.setEntry(2, 1, m21); m.setEntry(2, 2, m22);
    return m;
  }

  // ----------------------------------------------------------
  // Matrix → Euler angles (roll, pitch, yaw)
  // ----------------------------------------------------------
  EulerAngles _matrixToEuler(Matrix3 m) {
    // Extract row-major elements via entry(row, col)
    final m00 = m.entry(0, 0);
    final m10 = m.entry(1, 0), m11 = m.entry(1, 1), m12 = m.entry(1, 2);
    final m20 = m.entry(2, 0), m21 = m.entry(2, 1), m22 = m.entry(2, 2);

    // Using Z-Y-X (yaw-pitch-roll) decomposition
    final sy = -m20; // sin(pitch)
    final cy = sqrt(max(0.0, 1 - sy * sy));

    double roll, pitch, yaw;
    if (cy > 1e-6) {
      roll  = atan2(m21, m22); // around X
      pitch = asin(sy);        // around Y
      yaw   = atan2(m10, m00); // around Z
    } else {
      // Gimbal lock: pitch ~ ±90°
      roll  = atan2(-m12, m11);
      pitch = asin(sy);
      yaw   = 0.0;
    }

    return EulerAngles(
      roll * 180 / pi,
      pitch * 180 / pi,
      yaw * 180 / pi,
    );
  }
}

// ----------------------------------------------------------
// Data classes
// ----------------------------------------------------------

class VehicleOrientation {
  final double roll;   // degrees
  final double pitch;  // degrees
  final double yaw;    // degrees
  final Matrix3 rotationMatrix;

  VehicleOrientation({
    required this.roll,
    required this.pitch,
    required this.yaw,
    required this.rotationMatrix,
  });
}

class EulerAngles {
  final double roll;
  final double pitch;
  final double yaw;

  EulerAngles(this.roll, this.pitch, this.yaw);
}
