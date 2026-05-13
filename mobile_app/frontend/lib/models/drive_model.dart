import 'package:opsin/models/event_model.dart';

// Drive Model matching Supabase 'trips' table
class Drive {
  final int tripId;
  final int vehicleId;
  final DateTime startTime;
  final DateTime endTime;
  final double distance;
  // Score is not in the trips table, but kept optional if needed later or calculated
  final double? score;

  // Data points fetched separately from 'datatransmission'
  final List<SensorDataPoint>? sensorData;
  final List<DriveEvent>? events;

  const Drive({
    required this.tripId,
    required this.vehicleId,
    required this.startTime,
    required this.endTime,
    required this.distance,
    this.score,
    this.sensorData,
    this.events,
  });

  factory Drive.fromJson(Map<String, dynamic> json) {
    return Drive(
      tripId: json['tripid'] as int,
      vehicleId: json['vehicleid'] as int,
      startTime: DateTime.parse(json['starttime']),
      endTime: DateTime.parse(json['endtime']),
      // Handle double or int for distance
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Duration get duration => endTime.difference(startTime);

  Drive copyWith({
    List<SensorDataPoint>? sensorData,
    List<DriveEvent>? events,
  }) {
    return Drive(
      tripId: tripId,
      vehicleId: vehicleId,
      startTime: startTime,
      endTime: endTime,
      distance: distance,
      score: score,
      sensorData: sensorData ?? this.sensorData,
      events: events ?? this.events,
    );
  }
}

// Sensor Data Point matching 'datatransmission' table
class SensorDataPoint {
  final DateTime timeSent;
  final double accelX;
  final double accelY;
  final double accelZ;
  final double gyroX;
  final double gyroY;
  final double gyroZ;
  final double latitude;
  final double longitude;
  final double speed;
  final double bearing;

  const SensorDataPoint({
    required this.timeSent,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.bearing,
  });

  factory SensorDataPoint.fromJson(Map<String, dynamic> json) {
    return SensorDataPoint(
      timeSent: DateTime.parse(json['timesent']),
      accelX: (json['accelx'] as num?)?.toDouble() ?? 0.0,
      accelY: (json['accely'] as num?)?.toDouble() ?? 0.0,
      accelZ: (json['accelz'] as num?)?.toDouble() ?? 0.0,
      gyroX: (json['gyrox'] as num?)?.toDouble() ?? 0.0,
      gyroY: (json['gyroy'] as num?)?.toDouble() ?? 0.0,
      gyroZ: (json['gyroz'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      bearing: (json['bearing'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
