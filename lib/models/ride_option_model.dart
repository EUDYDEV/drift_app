enum RideType { withDriver, withoutDriver }

class RideOption {
  final RideType type;
  final String label; // "Avec chauffeur", "Sans chauffeur"
  final double price;
  final double estimatedPrice;
  final String estimatedTime; // "15-20 min"
  final String vehicleType; // "economy", "comfort", "premium"
  final String description;

  RideOption({
    required this.type,
    required this.label,
    required this.price,
    required this.estimatedPrice,
    required this.estimatedTime,
    required this.vehicleType,
    required this.description,
  });

  factory RideOption.fromJson(Map<String, dynamic> json) {
    return RideOption(
      type: RideType.values.byName(json['type'] as String),
      label: json['label'] as String,
      price: json['price'] as double,
      estimatedPrice: json['estimatedPrice'] as double,
      estimatedTime: json['estimatedTime'] as String,
      vehicleType: json['vehicleType'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'label': label,
      'price': price,
      'estimatedPrice': estimatedPrice,
      'estimatedTime': estimatedTime,
      'vehicleType': vehicleType,
      'description': description,
    };
  }
}
