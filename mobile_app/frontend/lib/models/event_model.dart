class DriveEvent {
  final int id;
  final int vehicleId;
  final DateTime timestamp;
  final String type;
  final String source; // 'camera' or 'imu'
  final String severity; // 'low', 'medium', 'high'
  final double confidence;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final DateTime endTimestamp; // Optional, for duration events

  const DriveEvent({
    required this.id,
    required this.vehicleId,
    required this.timestamp,
    required this.type,
    required this.source,
    required this.severity,
    required this.confidence,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    required this.endTimestamp,
  });

  factory DriveEvent.fromJson(Map<String, dynamic> json) {
    // Determine end timestamp, default to 1 sec later if not provided (e.g. for discrete events)
    // Note: Schema currently doesn't have end_timestamp, so we infer or might add it later.
    // For now, let's assume point events or short duration.
    final start = DateTime.parse(json['timestamp']);
    return DriveEvent(
      id: json['id'] as int,
      vehicleId: json['vehicle_id'] as int,
      timestamp: start,
      type: json['event_type'] as String,
      source: json['source'] as String,
      severity: json['severity'] as String? ?? 'medium',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] as String?,
      endTimestamp: start.add(Duration(seconds: 1)), // Default 1s duration
    );
  }
}
