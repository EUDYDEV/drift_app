class Location {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;
  final String? country;

  Location({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.country,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      address: json['address'] as String,
      city: json['city'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'country': country,
    };
  }

  double distanceTo(Location other) {
    // Haversine formula pour calculer distance
    const earthRadius = 6371; // km
    final dLat = _toRadians(other.latitude - latitude);
    final dLon = _toRadians(other.longitude - longitude);
    final a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(_toRadians(latitude)) *
            Math.cos(_toRadians(other.latitude)) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2);
    final c = 2 * Math.asin(Math.sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * 3.14159265359 / 180;
  }
}

// Mock pour Math.sin, Math.cos, etc.
class Math {
  static double sin(double x) => _sin(x);
  static double cos(double x) => _cos(x);
  static double asin(double x) => _asin(x);
  static double sqrt(double x) => x < 0 ? 0 : _sqrt(x);

  static double _sin(double x) {
    // Approximation simple
    x = x % (2 * 3.14159265359);
    return x - (x * x * x / 6) + (x * x * x * x * x / 120);
  }

  static double _cos(double x) {
    return _sin(x + 3.14159265359 / 2);
  }

  static double _asin(double x) {
    return x + (x * x * x / 6) + (3 * x * x * x * x * x / 40);
  }

  static double _sqrt(double x) {
    if (x == 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}
