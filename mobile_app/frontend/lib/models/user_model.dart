class AppUser {
  final String firebaseUid;
  final String email;
  final String name;
  final String username;
  final String? phone;
  final String? address;
  final String? profilePictureUrl;
  final int? rpsScore;
  final int? liquidEllar;
  final int? frozenEllar;
  final double? distance;

  const AppUser({
    required this.firebaseUid,
    required this.email,
    required this.name,
    required this.username,
    this.phone,
    this.address,
    this.profilePictureUrl,
    this.rpsScore,
    this.liquidEllar,
    this.frozenEllar,
    this.distance,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      firebaseUid: map['firebaseuid'] as String,
      email: (map['email'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      username: (map['username'] ?? '') as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      profilePictureUrl:
          (map['profile_picture_url'] ?? map['profilepictureurl']) as String?,
      rpsScore: (map['rpsscore'] as num?)?.toInt(),
      liquidEllar: (map['liquid_ellar'] as num?)?.toInt(),
      frozenEllar: (map['frozen_ellar'] as num?)?.toInt(),
      distance: (map['distance'] as num?)?.toDouble(),
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
      'profile_picture_url': profilePictureUrl,
      'rpsscore': rpsScore,
      'liquid_ellar': liquidEllar,
      'frozen_ellar': frozenEllar,
      'distance': distance,
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
    String? profilePictureUrl,
    int? rpsScore,
    int? liquidEllar,
    int? frozenEllar,
    double? distance,
  }) {
    return AppUser(
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      rpsScore: rpsScore ?? this.rpsScore,
      liquidEllar: liquidEllar ?? this.liquidEllar,
      frozenEllar: frozenEllar ?? this.frozenEllar,
      distance: distance ?? this.distance,
    );
  }
}
