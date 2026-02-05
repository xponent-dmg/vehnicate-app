class Vehicle {
  final int id;
  final String name;
  final String model;
  final String insurance;
  final String registration;
  final String? puc;

  const Vehicle({
    required this.id,
    required this.name,
    required this.model,
    required this.insurance,
    required this.registration,
    this.puc,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['vehicleid'] as int,
      name:
          json['name'] as String? ??
          'My Vehicle', // Default name if not present
      model: json['model'] as String? ?? 'Unknown Model',
      insurance: json['insurance'] as String? ?? '',
      registration: json['registration'] as String? ?? '',
      puc: json['puc']?.toString(), // Handle potential non-string types safely
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
    };
  }
}
