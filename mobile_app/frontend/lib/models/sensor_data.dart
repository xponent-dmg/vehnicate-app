// ignore_for_file: non_constant_identifier_names

/// Data model for IMU sensor readings.
class ImuData {
  final int timestamp;
  final double ax; // Accelerometer X (with gravity) in m/s²
  final double ay; // Accelerometer Y (with gravity) in m/s²
  final double az; // Accelerometer Z (with gravity) in m/s²
  final double gx; // Gyroscope X in deg/s
  final double gy; // Gyroscope Y in deg/s
  final double gz; // Gyroscope Z in deg/s
  final double Ax; // Linear acceleration X (without gravity) in m/s²
  final double Ay; // Linear acceleration Y (without gravity) in m/s²
  final double Az; // Linear acceleration Z (without gravity) in m/s²

  ImuData({
    required this.timestamp,
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
    required this.Ax,
    required this.Ay,
    required this.Az,
  });

  factory ImuData.fromMap(Map<dynamic, dynamic> map) {
    return ImuData(
      timestamp: map['timestamp'] as int,
      ax: (map['ax'] as num).toDouble(),
      ay: (map['ay'] as num).toDouble(),
      az: (map['az'] as num).toDouble(),
      gx: (map['gx'] as num).toDouble(),
      gy: (map['gy'] as num).toDouble(),
      gz: (map['gz'] as num).toDouble(),
      Ax: (map['Ax'] as num).toDouble(),
      Ay: (map['Ay'] as num).toDouble(),
      Az: (map['Az'] as num).toDouble(),
    );
  }
}

/// Data model for location/GPS data.
class GpsData {
  final int timestamp;
  final double latitude;
  final double longitude;
  final double speed;
  final double bearing;

  GpsData({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.bearing,
  });

  factory GpsData.fromMap(Map<dynamic, dynamic> map) {
    return GpsData(
      timestamp: map['timestamp'] as int,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      speed: (map['speed'] as num).toDouble(),
      bearing: (map['bearing'] as num).toDouble(),
    );
  }
}
