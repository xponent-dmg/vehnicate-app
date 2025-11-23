import 'dart:async';
import 'package:flutter/services.dart';
import '../models/sensor_data.dart';

/// Service for managing sensor data streaming from native platform.
class SensorService {
  static const EventChannel _eventChannel = EventChannel('vehnicate/sensors');

  StreamSubscription? _subscription;
  final StreamController<SensorPacket> _controller = StreamController<SensorPacket>.broadcast();

  /// Exposes the sensor data stream
  Stream<SensorPacket> get sensorStream => _controller.stream;

  /// Starts listening to sensor data from native platform
  void startListening() {
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        try {
          final packet = SensorPacket.fromMap(event as Map<dynamic, dynamic>);
          _controller.add(packet);
        } catch (e) {
          _controller.addError(e);
        }
      },
      onError: (dynamic error) {
        _controller.addError(error);
      },
    );
  }

  /// Stops listening to sensor data
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Disposes resources
  void dispose() {
    stopListening();
    _controller.close();
  }
}
