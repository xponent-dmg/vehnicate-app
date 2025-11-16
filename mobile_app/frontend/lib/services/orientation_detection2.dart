import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
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
  // Output stream
  final _vehicleOrientationController =
      StreamController<VehicleOrientation>.broadcast();
  Stream<VehicleOrientation> get vehicleOrientationStream =>
      _vehicleOrientationController.stream;

  // Sensor subscriptions
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  // Latest sensor samples
  Vector3? _gravity; // low-pass filtered accelerometer (approximates gravity)
  Vector3? _mag;     // low-pass filtered magnetometer

  // Throttle
  DateTime _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);
  final Duration _emitInterval = const Duration(milliseconds: 50);

  // Mounting matrix (phone → vehicle)
  // Phone X → Vehicle Y
  // Phone Y → Vehicle Z
  // Phone Z → Vehicle X
  //
  // [ 0  0  1 ]   Phone Z -> Vehicle X
  // [ 1  0  0 ]   Phone X -> Vehicle Y
  // [ 0  1  0 ]   Phone Y -> Vehicle Z
  final Matrix3 R_mount = Matrix3(
    0, 0, 1,
    1, 0, 0,
    0, 1, 0,
  );

  void start() {
    // Low-pass parameters
    const double alphaAccel = 0.90; // higher = smoother gravity
    const double alphaMag = 0.90;

    _accelSub = accelerometerEvents.listen((e) {
      // Low-pass filter accelerometer to approximate gravity vector
      final a = Vector3(e.x, e.y, e.z);
      _gravity = _lowPass(_gravity, a, alphaAccel);

      _maybeEmit();
    });

    _magSub = magnetometerEvents.listen((e) {
      final m = Vector3(e.x, e.y, e.z);
      _mag = _lowPass(_mag, m, alphaMag);

      _maybeEmit();
    });
  }

  void stop() {
    _accelSub?.cancel();
    _magSub?.cancel();
    _vehicleOrientationController.close();
  }

  Vector3 _lowPass(Vector3? prev, Vector3 input, double alpha) {
    if (prev == null) return input;
    return Vector3(
      alpha * prev.x + (1 - alpha) * input.x,
      alpha * prev.y + (1 - alpha) * input.y,
      alpha * prev.z + (1 - alpha) * input.z,
    );
  }

  void _maybeEmit() {
    // Need both gravity and magnetometer samples
    if (_gravity == null || _mag == null) return;

    final now = DateTime.now();
    if (now.difference(_lastEmit) < _emitInterval) return;
    _lastEmit = now;

    final R_phone = _computeRotationMatrixFromAccelMag(_gravity!, _mag!);
    if (R_phone == null) return; // degenerate case (e.g., zero field)

    // Map phone → vehicle
    final R_vehicle = R_mount * R_phone;

    // Extract Euler angles (degrees) from vehicle rotation
    final angles = _matrixToEuler(R_vehicle);

    _vehicleOrientationController.add(
      VehicleOrientation(
        roll: angles.roll,
        pitch: angles.pitch,
        yaw: angles.yaw,
        rotationMatrix: R_vehicle,
      ),
    );
  }

  // Build phone→world rotation matrix using tilt-compensated compass
  // World axes: East (row 0), North (row 1), Up (row 2)
  Matrix3? _computeRotationMatrixFromAccelMag(Vector3 accel, Vector3 mag) {
    // Normalize gravity (Up approximates gravity direction sign; on most devices
    // accelerometer at rest points upward ~ +9.8 so Up ≈ normalize(accel))
    final g = accel.clone();
    if (g.length2 == 0) return null;
    g.normalize();

    // Compute East = mag × g
    final E = mag.clone()..cross(g);
    final eLen2 = E.length2;
    if (eLen2 < 1e-12) return null;
    E.scale(1 / sqrt(eLen2));

    // North = g × E
    final N = g.clone()..cross(E);
    final nLen2 = N.length2;
    if (nLen2 < 1e-12) return null;
    N.scale(1 / sqrt(nLen2));

    final U = g; // Up

    // Compose rotation matrix R (device → world), rows: E; N; U
    final R = Matrix3.zero();
    // row 0 = East
    R.setEntry(0, 0, E.x); R.setEntry(0, 1, E.y); R.setEntry(0, 2, E.z);
    // row 1 = North
    R.setEntry(1, 0, N.x); R.setEntry(1, 1, N.y); R.setEntry(1, 2, N.z);
    // row 2 = Up
    R.setEntry(2, 0, U.x); R.setEntry(2, 1, U.y); R.setEntry(2, 2, U.z);

    return R;
  }

  // Matrix → Euler angles (roll, pitch, yaw) using Z-Y-X convention
  EulerAngles _matrixToEuler(Matrix3 m) {
    final m00 = m.entry(0, 0);
    final m10 = m.entry(1, 0), m11 = m.entry(1, 1), m12 = m.entry(1, 2);
    final m20 = m.entry(2, 0), m21 = m.entry(2, 1), m22 = m.entry(2, 2);

    final sy = -m20; // sin(pitch)
    final cy = sqrt(max(0.0, 1 - sy * sy));

    double roll, pitch, yaw;
    if (cy > 1e-6) {
      roll = atan2(m21, m22); // X
      pitch = asin(sy);       // Y
      yaw = atan2(m10, m00);  // Z
    } else {
      // Gimbal lock
      roll = atan2(-m12, m11);
      pitch = asin(sy);
      yaw = 0.0;
    }

    return EulerAngles(
      roll * 180 / pi,
      pitch * 180 / pi,
      yaw * 180 / pi,
    );
  }
}

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