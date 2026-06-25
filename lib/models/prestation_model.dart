class PrestationModel {
  final String id;
  final String partnerId;
  final String typeService;
  final String name;
  final double price;
  final String? cuisineCategory;
  final int? capacity;
  final bool isAvailable;
  final List<String> mediaUrls;
  final Map<String, dynamic> details;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PrestationModel({
    required this.id,
    required this.partnerId,
    required this.typeService,
    required this.name,
    required this.price,
    required this.cuisineCategory,
    required this.capacity,
    required this.isAvailable,
    required this.mediaUrls,
    required this.details,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PrestationModel.fromJson(Map<String, dynamic> json) {
    return PrestationModel(
      id: json['id']?.toString() ?? '',
      partnerId: (json['partnerId'] ??
              json['partenaireId'] ??
              json['partner_id'] ??
              json['partenaire_id'])
          ?.toString() ??
          '',
      typeService:
          (json['typeService'] ?? json['type_service'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      price: _readDouble(json['price']),
      cuisineCategory:
          (json['cuisineCategory'] ?? json['cuisine_category'])?.toString(),
      capacity: _readInt(json['capacity']),
      isAvailable:
          (json['isAvailable'] ?? json['is_available']) as bool? ?? false,
      mediaUrls: _readStringList(json['mediaUrls'] ?? json['media_urls']),
      details: _readObject(json['details']),
      createdAt: _readDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _readDateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partnerId': partnerId,
      'typeService': typeService,
      'name': name,
      'price': price,
      'cuisineCategory': cuisineCategory,
      'capacity': capacity,
      'isAvailable': isAvailable,
      'mediaUrls': mediaUrls,
      'details': details,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  PrestationModel copyWith({
    String? id,
    String? partnerId,
    String? typeService,
    String? name,
    double? price,
    String? cuisineCategory,
    int? capacity,
    bool? isAvailable,
    List<String>? mediaUrls,
    Map<String, dynamic>? details,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrestationModel(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      typeService: typeService ?? this.typeService,
      name: name ?? this.name,
      price: price ?? this.price,
      cuisineCategory: cuisineCategory ?? this.cuisineCategory,
      capacity: capacity ?? this.capacity,
      isAvailable: isAvailable ?? this.isAvailable,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static double _readDouble(dynamic raw) {
    return (raw as num?)?.toDouble() ?? 0;
  }

  static int? _readInt(dynamic raw) {
    return (raw as num?)?.toInt();
  }

  static DateTime? _readDateTime(dynamic raw) {
    if (raw == null) {
      return null;
    }
    return DateTime.tryParse(raw.toString());
  }

  static List<String> _readStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((item) => item.toString()).toList(growable: false);
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return <String>[raw.trim()];
    }
    return const <String>[];
  }

  static Map<String, dynamic> _readObject(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    return const <String, dynamic>{};
  }
}
