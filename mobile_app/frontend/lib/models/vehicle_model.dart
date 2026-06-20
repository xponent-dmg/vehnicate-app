class Vehicle {
  final int id;
  final String name;
  final String model;
  final String? insurance;
  final String registration;
  final String? puc;
  final double? distance;

  const Vehicle({
    required this.id,
    required this.name,
    required this.model,
    this.insurance,
    required this.registration,
    this.puc,
    this.distance,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['vehicleid'] as int,
      name:
          json['name'] as String? ??
          'My Vehicle', // Default name if not present
      model: json['model'] as String? ?? 'Unknown Model',
      insurance: json['insurance'] as String?,
      registration: json['registration'] as String? ?? '',
      puc: json['puc']?.toString(), // Handle potential non-string types safely
      distance: (json['distance'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleid': id,
      'name': name,
      'model': model,
      'insurance': insurance,
      'registration': registration,
      'puc': puc,
      'distance': distance,
    };
  }

  /// Formats the registration number for UI rendering (e.g., "AA 00 AA 0000")
  String get formattedRegistration {
    if (registration.isEmpty) return registration;

    // Remove any existing spaces or special characters
    final cleanReg =
        registration.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();

    // Use regex to match the standard Indian vehicle number format
    // 2 Letters, 1-2 digits, 1-3 Letters, 1-4 digits
    final regex = RegExp(r'^([A-Z]{2})(\d{1,2})([A-Z]{1,3})(\d{1,4})$');
    final match = regex.firstMatch(cleanReg);

    if (match != null) {
      return '${match.group(1)} ${match.group(2)} ${match.group(3)} ${match.group(4)}';
    }

    // If it doesn't match standard format perfectly but has enough characters,
    // we can fallback to simple spacing if the length is 10 (AA00AA0000)
    if (cleanReg.length == 10) {
      return '${cleanReg.substring(0, 2)} ${cleanReg.substring(2, 4)} ${cleanReg.substring(4, 6)} ${cleanReg.substring(6, 10)}';
    }

    return registration;
  }
}
