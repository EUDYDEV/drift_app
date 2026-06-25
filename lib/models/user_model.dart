// User model
class User {
  final String id;
  final String email;
  final String phone;
  final String fullName;
  final double accountBalance;
  final double activeFineAmount;
  final bool isRestricted;
  final String? restrictionReason;
  final String? profileImage;
  final DateTime createdAt;
  final List<String> savedAddresses;

  User({
    required this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    this.accountBalance = 0,
    this.activeFineAmount = 0,
    this.isRestricted = false,
    this.restrictionReason,
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
      'accountBalance': accountBalance,
      'activeFineAmount': activeFineAmount,
      'isRestricted': isRestricted,
      'restrictionReason': restrictionReason,
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
      phone: (json['phone'] ?? '') as String,
      fullName: (json['fullName'] ?? json['full_name'] ?? '') as String,
      accountBalance:
          _readDouble(json['accountBalance'] ?? json['account_balance']),
      activeFineAmount: _readDouble(
        json['activeFineAmount'] ??
            json['active_fine_amount'] ??
            json['penaltyBalance'] ??
            json['penalty_balance'],
      ),
      isRestricted:
          (json['isRestricted'] ?? json['is_restricted']) as bool? ?? false,
      restrictionReason:
          (json['restrictionReason'] ?? json['restriction_reason']) as String?,
      profileImage: json['profileImage'] as String?,
      createdAt: DateTime.parse(
        (json['createdAt'] ?? json['created_at']) as String,
      ),
      savedAddresses: List<String>.from(json['savedAddresses'] as List? ?? []),
    );
  }

  // Copy with
  User copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    double? accountBalance,
    double? activeFineAmount,
    bool? isRestricted,
    String? restrictionReason,
    String? profileImage,
    DateTime? createdAt,
    List<String>? savedAddresses,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      accountBalance: accountBalance ?? this.accountBalance,
      activeFineAmount: activeFineAmount ?? this.activeFineAmount,
      isRestricted: isRestricted ?? this.isRestricted,
      restrictionReason: restrictionReason ?? this.restrictionReason,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      savedAddresses: savedAddresses ?? this.savedAddresses,
    );
  }

  static double _readDouble(dynamic raw) {
    return (raw as num?)?.toDouble() ?? 0;
  }
}
