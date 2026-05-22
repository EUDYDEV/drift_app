// User model
class User {
  final String id;
  final String email;
  final String phone;
  final String fullName;
  final String? profileImage;
  final DateTime createdAt;
  final List<String> savedAddresses;

  User({
    required this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    this.profileImage,
    required this.createdAt,
    this.savedAddresses = const [],
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'fullName': fullName,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'savedAddresses': savedAddresses,
    };
  }

  // Create from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      fullName: json['fullName'] as String,
      profileImage: json['profileImage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      savedAddresses: List<String>.from(json['savedAddresses'] as List? ?? []),
    );
  }

  // Copy with
  User copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    String? profileImage,
    DateTime? createdAt,
    List<String>? savedAddresses,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      savedAddresses: savedAddresses ?? this.savedAddresses,
    );
  }
}
