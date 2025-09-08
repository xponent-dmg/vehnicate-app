// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vehnicate_frontend/services/imu_service.dart';

class ImuCollector extends StatefulWidget {
  const ImuCollector({super.key});

  @override
  State<ImuCollector> createState() => _ImuCollectorState();
}

class _ImuCollectorState extends State<ImuCollector> {
  final ImuService _imuService = ImuService();
  bool isCollecting = false;
  final supabase = Supabase.instance.client;

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
    await _imuService.start(
      context: context,
      vehicleId: 1,
      manageLocationStream: true,
      useUserAccelerometer: false,
      authProvider: AuthProvider.supabase,
    );
  }

  void stopCollection() {
    _imuService.stop(context, authProvider: AuthProvider.supabase);
    setState(() => isCollecting = false);
  }

  @override
  void dispose() {
    _imuService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("IMU + GPS Collector test page")),
      body: Center(
        child: ElevatedButton(
          onPressed: isCollecting ? stopCollection : startCollection,
          child: Text(isCollecting ? "Stop data collection" : "Start data collection"),
        ),
      ),
    );
  }
}
