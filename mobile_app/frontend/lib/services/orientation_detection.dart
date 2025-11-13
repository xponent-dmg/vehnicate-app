import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

// Global constants for gravity and classification thresholds
const double GRAVITY_EARTH = 9.81;
const double THRESHOLD_PITCH_ROLL = 45.0; // Angle threshold for side-to-side/front-to-back tilt

class OrientationDetector extends StatefulWidget {
  const OrientationDetector({super.key});

  @override
  State<OrientationDetector> createState() => _OrientationDetectorState();
}

class _OrientationDetectorState extends State<OrientationDetector> {
  // Raw Sensor Data
  AccelerometerEvent _accelerometerEvent = AccelerometerEvent(0, 0, 0, DateTime.now());

  // Calculated Pitch and Roll
  double _pitch = 0.0;
  double _roll = 0.0;

  // World-relative direction
  String _downDirection = 'Unknown';
  String _upDirection = 'Unknown';

  late StreamSubscription<AccelerometerEvent> _accelSubscription;

  @override
  void initState() {
    super.initState();
    // Start listening to the accelerometer stream
    _accelSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        setState(() {
          _accelerometerEvent = event;
          _updateOrientation();
        });
      },
      onError: (error) {
        // Handle error in sensor access
        setState(() {
          _downDirection = 'Sensor Error: $error';
        });
      },
      cancelOnError: true,
    );
  }

  @override
  void dispose() {
    _accelSubscription.cancel();
    super.dispose();
  }

  // --- CORE LOGIC: DETERMINING PITCH AND ROLL ---
  void _updateOrientation() {
    final x = _accelerometerEvent.x;
    final y = _accelerometerEvent.y;
    final z = _accelerometerEvent.z;

    // Calculate the magnitude of the gravitational vector
    final mag = sqrt(x * x + y * y + z * z);

    if (mag > 0.1) {
      // 1. Roll (Rotation around the X-axis - side to side tilt)
      // The accelerometer X and Z components are used to find the angle
      // atan2(Y-component, Z-component for X-axis rotation)
      _roll = atan2(y, z) * 180 / pi;

      // 2. Pitch (Rotation around the Y-axis - front to back tilt)
      // The accelerometer X and Z components are used to find the angle
      // atan2(X-component, sqrt(Y^2 + Z^2))
      // Note: We use -x for standard sign convention (forward tilt is negative pitch)
      _pitch = atan2(-x, sqrt(y * y + z * z)) * 180 / pi;

      // Determine the direction closest to "Down" (gravity)
      _classifyWorldDirections();
    }
  }

  // --- CORE LOGIC: CLASSIFYING WORLD DIRECTIONS ---
  void _classifyWorldDirections() {
    // The angles (_pitch and _roll) are now relative to the world's gravity vector.
    // We determine which physical side of the phone is facing the largest gravity component.

    // Get the absolute values for simple comparison
    final absPitch = _pitch.abs();
    final absRoll = _roll.abs();

    // The two main planes are:
    // 1. The Screen Plane (Pitch/Roll are near 0/180 or near 0/-180)
    // 2. The Edge Plane (Pitch/Roll are near 90 or -90)

    if (absPitch < THRESHOLD_PITCH_ROLL && absRoll < THRESHOLD_PITCH_ROLL) {
      // Case 1: Phone is mostly flat, screen up or screen down.
      // Z-axis component of gravity is dominant.
      if (_accelerometerEvent.z > 8.0) {
        // Positive Z-axis acceleration means screen is UP
        _downDirection = 'Back of Phone';
        _upDirection = 'Screen Surface';
      } else if (_accelerometerEvent.z < -8.0) {
        // Negative Z-axis acceleration means screen is DOWN
        _downDirection = 'Screen Surface';
        _upDirection = 'Back of Phone';
      } else {
        // Flat but gravity not entirely on Z. Handle edge cases.
        _downDirection = 'Level (Screen Flat)';
        _upDirection = 'Level (Screen Flat)';
      }
    } else {
      // Case 2: Phone is on its side, top, or bottom edge.
      // Determine dominant angle (Pitch or Roll)
      if (absPitch > absRoll) {
        // Pitch is dominant (phone is tilted forward/backward, Z-axis tilt)
        if (_pitch > THRESHOLD_PITCH_ROLL) {
          _downDirection = 'Top Edge (Camera Side)';
          _upDirection = 'Bottom Edge (Charging Port)';
        } else if (_pitch < -THRESHOLD_PITCH_ROLL) {
          _downDirection = 'Bottom Edge (Charging Port)';
          _upDirection = 'Top Edge (Camera Side)';
        }
      } else {
        // Roll is dominant (phone is tilted side-to-side, Y-axis tilt)
        if (_roll > THRESHOLD_PITCH_ROLL) {
          _downDirection = 'Right Edge';
          _upDirection = 'Left Edge';
        } else if (_roll < -THRESHOLD_PITCH_ROLL) {
          _downDirection = 'Left Edge';
          _upDirection = 'Right Edge';
        }
      }
    }
  }

  // --- UI BUILDING ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('World-Frame Direction Detector'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // The Down/Up Display Card
            _buildDirectionCard(),

            const SizedBox(height: 30),

            // Raw Sensor Data
            _buildSensorDataDisplay(),

            const SizedBox(height: 30),

            // Calculated Angles Display
            _buildAngleDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.deepPurple.shade900,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.public, color: Colors.white, size: 40),
            const SizedBox(height: 12),
            const Text(
              'World-Relative Orientation',
              style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.w300),
            ),
            const Divider(color: Colors.deepPurple),
            _buildDirectionRow('DOWN (Gravity)', _downDirection, Colors.redAccent),
            const SizedBox(height: 10),
            _buildDirectionRow('UP (Anti-Gravity)', _upDirection, Colors.greenAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionRow(String title, String direction, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(direction, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildSensorDataDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Raw Accelerometer Data (m/s²)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(),
        _buildDataRow('X-Axis (Right/Left)', '${_accelerometerEvent.x.toStringAsFixed(2)} m/s²'),
        _buildDataRow('Y-Axis (Top/Bottom)', '${_accelerometerEvent.y.toStringAsFixed(2)} m/s²'),
        _buildDataRow('Z-Axis (Screen/Back)', '${_accelerometerEvent.z.toStringAsFixed(2)} m/s²'),
      ],
    );
  }

  Widget _buildAngleDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Calculated Orientation Angles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(),
        _buildDataRow('Pitch (Forward/Backward)', '${_pitch.toStringAsFixed(2)}°'),
        _buildDataRow('Roll (Side-to-Side)', '${_roll.toStringAsFixed(2)}°'),
        const SizedBox(height: 10),
        const Text(
          '*Note: This method uses the Accelerometer only. For accurate Left/Right/North/South relative to the Earth (true "world-frame" directions), a full Sensor Fusion implementation using the Magnetometer and Gyroscope is required.',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.white)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent)),
        ],
     )
    );
  }
}