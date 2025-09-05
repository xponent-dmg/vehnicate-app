class AppUser {
  final String firebaseUid;
  final String email;
  final String name;
  final String username;
  final String? phone;
  final String? address;
  final int? vehicleId;
  final int? rpsScore;

  const AppUser({
    required this.firebaseUid,
    required this.email,
    required this.name,
    required this.username,
    this.phone,
    this.address,
    this.vehicleId,
    this.rpsScore,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      firebaseUid: map['firebaseuid'] as String,
      email: (map['email'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      username: (map['username'] ?? '') as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      vehicleId: (map['vehicleid'] as num?)?.toInt(),
      rpsScore: (map['rpsscore'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firebaseuid': firebaseUid,
      'email': email,
      'name': name,
      'username': username,
      'phone': phone,
      'address': address,
      'vehicleid': vehicleId,
      'rpsscore': rpsScore,
    }..removeWhere((key, value) => value == null);
  }

  AppUser copyWith({
    String? firebaseUid,
    String? supabaseUid,
    String? email,
    String? name,
    String? username,
    String? phone,
    String? address,
    int? vehicleId,
    int? rpsScore,
  }) {
    return AppUser(
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      vehicleId: vehicleId ?? this.vehicleId,
      rpsScore: rpsScore ?? this.rpsScore,
    );
  }
}
