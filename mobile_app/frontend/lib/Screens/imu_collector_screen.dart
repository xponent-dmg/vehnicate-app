// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class ImuCollector extends StatefulWidget {
  const ImuCollector({super.key});

  @override
  State<ImuCollector> createState() => _ImuCollectorState();
}

class _ImuCollectorState extends State<ImuCollector> {
  List<Map<String, dynamic>> imuBuffer = [];
  StreamSubscription? accelSub;
  StreamSubscription? gyroSub;
  StreamSubscription<Position>? positionSub;
  Timer? uploadTimer;
  bool isCollecting = false;
  final supabase = Supabase.instance.client;

  double? gx, gy, gz;
  double latitude = 0.0;
  double longitude = 0.0;
  double speed = 0.0;

  Future<void> initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Check permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, cannot request.');
    }
  }

  void startCollection() async {
    if (isCollecting) return;
    await initLocation();
    setState(() => isCollecting = true);

    // Show snackbar for starting collection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📱 Started sensor data collection'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Gyroscope stream
    gyroSub = gyroscopeEvents.listen((event) {
      gx = event.x;
      gy = event.y;
      gz = event.z;
    });

    // Accelerometer stream
    accelSub = accelerometerEvents.listen((event) {
      final imuData = {
        "vehicleid": 1, // 🔹 replace with actual vehicle ID
        "timesent": DateTime.now().toIso8601String(),
        "accelx": event.x,
        "accely": event.y,
        "accelz": event.z,
        "gyrox": gx ?? 0,
        "gyroy": gy ?? 0,
        "gyroz": gz ?? 0,
        "latitude": latitude,
        "longitude": longitude,
        "speed": speed,
      };
      print("Adding IMU data to buffer: $imuData");
      imuBuffer.add(imuData);
    });

    // Location updates
    positionSub = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // meters before update
      ),
    ).listen((Position position) {
      latitude = position.latitude;
      longitude = position.longitude;
      speed = position.speed; // meters/second
    });

    // Upload buffer every 10s
    uploadTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      if (imuBuffer.isNotEmpty) {
        // Show snackbar for data upload
        print("📤 Timer triggered - uploading ${imuBuffer.length} records");
        List<Map<String, dynamic>> temp = List.from(imuBuffer);
        imuBuffer.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📤 Uploaded ${temp.length} sensor records'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 1),
          ),
        );
        await sendToSupabase(temp);
      } else {
        print("⏰ Upload timer triggered but buffer is empty");
      }
    });
  }

  void stopCollection() {
    accelSub?.cancel();
    gyroSub?.cancel();
    positionSub?.cancel();
    uploadTimer?.cancel();
    setState(() => isCollecting = false);

    // Show snackbar for stopping collection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⏹️ Stopped sensor data collection'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> sendToSupabase(List<Map<String, dynamic>> data) async {
    try {
      print("Attempting to send ${data.length} records to Supabase...");
      print("Sample data: ${data.isNotEmpty ? data.first : 'No data'}");

      final response = await supabase.from('datatransmission').insert(data);
      print("✅ Successfully sent ${data.length} records to Supabase");
      print("Response: $response");
    } catch (e) {
      print("❌ Error sending data to Supabase: $e");
      print("Error type: ${e.runtimeType}");
      if (e is PostgrestException) {
        print("PostgrestException details:");
        print("  Code: ${e.code}");
        print("  Message: ${e.message}");
        print("  Details: ${e.details}");
        print("  Hint: ${e.hint}");
      }
      imuBuffer.addAll(data); // retry later
    }
  }

  @override
  void dispose() {
    stopCollection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("IMU + GPS Collector")),
      body: Center(
        child: ElevatedButton(
          onPressed: isCollecting ? stopCollection : startCollection,
          child: Text(isCollecting ? "Stop Collection" : "Start Collection"),
        ),
      ),
    );
  }
}
