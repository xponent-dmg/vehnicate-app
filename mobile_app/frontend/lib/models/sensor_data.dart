// ignore_for_file: non_constant_identifier_names

/// Data model for raw sensor readings from the device.
class RawSensorData {
  final double ax; // Accelerometer X (with gravity) in m/s²
  final double ay; // Accelerometer Y (with gravity) in m/s²
  final double az; // Accelerometer Z (with gravity) in m/s²
  final double Ax; // Linear acceleration X (without gravity) in m/s²
  final double Ay; // Linear acceleration Y (without gravity) in m/s²
  final double Az; // Linear acceleration Z (without gravity) in m/s²
  final double Gx; // Gyroscope X in deg/s
  final double Gy; // Gyroscope Y in deg/s
  final double Gz; // Gyroscope Z in deg/s
  final double Mx; // Magnetometer X in µT
  final double My; // Magnetometer Y in µT
  final double Mz; // Magnetometer Z in µT

  RawSensorData({
    required this.ax,
    required this.ay,
    required this.az,
    required this.Ax,
    required this.Ay,
    required this.Az,
    required this.Gx,
    required this.Gy,
    required this.Gz,
    this.Mx = 0.0,
    this.My = 0.0,
    this.Mz = 0.0,
  });

  factory RawSensorData.fromMap(Map<dynamic, dynamic> map) {
    return RawSensorData(
      ax: (map['ax'] as num).toDouble(),
      ay: (map['ay'] as num).toDouble(),
      az: (map['az'] as num).toDouble(),
      Ax: (map['Ax'] as num).toDouble(),
      Ay: (map['Ay'] as num).toDouble(),
      Az: (map['Az'] as num).toDouble(),
      Gx: (map['Gx'] as num).toDouble(),
      Gy: (map['Gy'] as num).toDouble(),
      Gz: (map['Gz'] as num).toDouble(),
      Mx: (map['Mx'] as num?)?.toDouble() ?? 0.0,
      My: (map['My'] as num?)?.toDouble() ?? 0.0,
      Mz: (map['Mz'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Data model for converted sensor data in vehicle coordinates.
class ConvertedData {
  final double AX; // Converted acceleration X in m/s²
  final double AY; // Converted acceleration Y in m/s²
  final double AZ; // Converted acceleration Z in m/s²
  final double GX; // Converted gyroscope X in deg/s
  final double GY; // Converted gyroscope Y in deg/s
  final double GZ; // Converted gyroscope Z in deg/s

  ConvertedData({
    required this.AX,
    required this.AY,
    required this.AZ,
    required this.GX,
    required this.GY,
    required this.GZ,
  });

  factory ConvertedData.fromMap(Map<dynamic, dynamic> map) {
    return ConvertedData(
      AX: (map['AX'] as num).toDouble(),
      AY: (map['AY'] as num).toDouble(),
      AZ: (map['AZ'] as num).toDouble(),
      GX: (map['GX'] as num).toDouble(),
      GY: (map['GY'] as num).toDouble(),
      GZ: (map['GZ'] as num).toDouble(),
    );
  }
}

/// Data model for conversion angles.
class ConversionAngles {
  final double theta; // Theta angle in radians
  final double phi; // Phi angle in radians

  ConversionAngles({required this.theta, required this.phi});

  factory ConversionAngles.fromMap(Map<dynamic, dynamic> map) {
    return ConversionAngles(theta: (map['theta'] as num).toDouble(), phi: (map['phi'] as num).toDouble());
  }

  /// Get theta in degrees
  double get thetaDegrees => theta * 180 / 3.14159265359;

  /// Get phi in degrees
  double get phiDegrees => phi * 180 / 3.14159265359;
}

/// Data model for location/GPS data.
class LocationData {
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final double bearing;
  final double accuracy;
  final bool hasLocation;

  LocationData({
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.altitude = 0.0,
    this.speed = 0.0,
    this.bearing = 0.0,
    this.accuracy = 0.0,
    this.hasLocation = false,
  });

  factory LocationData.fromMap(Map<dynamic, dynamic> map) {
    return LocationData(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      altitude: (map['altitude'] as num).toDouble(),
      speed: (map['speed'] as num).toDouble(),
      bearing: (map['bearing'] as num).toDouble(),
      accuracy: (map['accuracy'] as num).toDouble(),
      hasLocation: map['hasLocation'] as bool,
    );
  }
}

/// Complete sensor data packet containing raw data, converted data, angles, and location.
class SensorPacket {
  final int timestamp;
  final RawSensorData raw;
  final ConvertedData converted;
  final ConversionAngles angles;
  final LocationData location;

  SensorPacket({
    required this.timestamp,
    required this.raw,
    required this.converted,
    required this.angles,
    required this.location,
  });

  factory SensorPacket.fromMap(Map<dynamic, dynamic> map) {
    return SensorPacket(
      timestamp: map['timestamp'] as int,
      raw: RawSensorData.fromMap(map['raw'] as Map<dynamic, dynamic>),
      converted: ConvertedData.fromMap(map['converted'] as Map<dynamic, dynamic>),
      angles: ConversionAngles.fromMap(map['angles'] as Map<dynamic, dynamic>),
      location: LocationData.fromMap(map['location'] as Map<dynamic, dynamic>),
    );
  }
}
