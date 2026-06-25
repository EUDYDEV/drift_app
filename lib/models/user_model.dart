// User model
class User {
  final String id;
  final String email;
  final String phone;
  final String fullName;
  final String role;
  final double accountBalance;
  final double activeFineAmount;
  final bool isRestricted;
  final String? restrictionReason;
  final bool identityDocumentsVerified;
  final String drivingLicenseStatus;
  final String? profileImage;
  final DateTime createdAt;
  final List<String> savedAddresses;

  User({
    required this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    this.role = 'client',
    this.accountBalance = 0,
    this.activeFineAmount = 0,
    this.isRestricted = false,
    this.restrictionReason,
    this.identityDocumentsVerified = false,
    this.drivingLicenseStatus = 'missing',
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
      'role': role,
      'accountBalance': accountBalance,
      'activeFineAmount': activeFineAmount,
      'isRestricted': isRestricted,
      'restrictionReason': restrictionReason,
      'identityDocumentsVerified': identityDocumentsVerified,
      'drivingLicenseStatus': drivingLicenseStatus,
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
      role: json['role'] as String? ?? 'client',
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
      identityDocumentsVerified: (json['identityDocumentsVerified'] ??
              json['identity_documents_verified']) as bool? ??
          false,
      drivingLicenseStatus: (json['drivingLicenseStatus'] ??
              json['driving_license_status']) as String? ??
          'missing',
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
    String? role,
    double? accountBalance,
    double? activeFineAmount,
    bool? isRestricted,
    String? restrictionReason,
    bool? identityDocumentsVerified,
    String? drivingLicenseStatus,
    String? profileImage,
    DateTime? createdAt,
    List<String>? savedAddresses,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      accountBalance: accountBalance ?? this.accountBalance,
      activeFineAmount: activeFineAmount ?? this.activeFineAmount,
      isRestricted: isRestricted ?? this.isRestricted,
      restrictionReason: restrictionReason ?? this.restrictionReason,
      identityDocumentsVerified:
          identityDocumentsVerified ?? this.identityDocumentsVerified,
      drivingLicenseStatus: drivingLicenseStatus ?? this.drivingLicenseStatus,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      savedAddresses: savedAddresses ?? this.savedAddresses,
    );
  }

  static double _readDouble(dynamic raw) {
    return (raw as num?)?.toDouble() ?? 0;
  }
}
