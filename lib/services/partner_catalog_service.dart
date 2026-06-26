import 'dart:convert';

import '../models/cart_model.dart';
import '../models/hotel_model.dart';
import '../models/location_model.dart';
import '../models/partner_catalog_prestation.dart';
import '../models/room_model.dart';
import 'api_service.dart';

class PartnerCatalogService {
  Future<List<PartnerCatalogPrestation>> fetchPrestations({
    Iterable<String>? prestationIds,
    String? typeService,
    String? partnerId,
  }) async {
    final ids = prestationIds
        ?.map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (prestationIds != null && (ids == null || ids.isEmpty)) {
      return const <PartnerCatalogPrestation>[];
    }

    final queryParameters = <String, String>{};
    if (ids != null && ids.isNotEmpty) {
      queryParameters['ids'] = ids.join(',');
    }

    final normalizedTypeService = typeService?.trim();
    if (normalizedTypeService != null && normalizedTypeService.isNotEmpty) {
      queryParameters['type_service'] = normalizedTypeService;
    }

    final normalizedPartnerId = partnerId?.trim();
    if (normalizedPartnerId != null && normalizedPartnerId.isNotEmpty) {
      queryParameters['partner_id'] = normalizedPartnerId;
    }

    final uri = Uri(
      path: '/partners/catalog/prestations',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    final response = await ApiService.get(uri.toString());
    if (response.statusCode != 200) {
      throw Exception(
        'Impossible de charger le catalogue partenaire (${response.statusCode})',
      );
    }

    final raw = json.decode(response.body);
    if (raw is! List) {
      throw const FormatException('Expected a list of partner prestations');
    }

    return raw
        .map(
          (item) => PartnerCatalogPrestation.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
  }

  Future<Map<String, PartnerCatalogPrestation>> fetchPrestationsByIds(
    Iterable<String> prestationIds,
  ) async {
    final prestations = await fetchPrestations(prestationIds: prestationIds);
    if (prestations.isEmpty) {
      return const <String, PartnerCatalogPrestation>{};
    }

    return {
      for (final prestation in prestations) prestation.id: prestation,
    };
  }

  Future<List<PartnerCatalogPrestation>> fetchAvailableByService({
    required String typeService,
    String? city,
    String? cuisineCategory,
    int? minimumCapacity,
  }) async {
    final prestations = await fetchPrestations(typeService: typeService);
    final normalizedCuisine = _normalizeLabel(cuisineCategory);

    final filtered = prestations.where((prestation) {
      if (!prestation.isAvailable) {
        return false;
      }
      if (!_matchesCity(prestation, city)) {
        return false;
      }
      if (normalizedCuisine != null &&
          normalizedCuisine.isNotEmpty &&
          _normalizeLabel(prestation.cuisineCategory) != normalizedCuisine) {
        return false;
      }
      if (minimumCapacity != null &&
          minimumCapacity > 0 &&
          (prestation.capacity ?? 0) < minimumCapacity) {
        return false;
      }
      return true;
    }).toList(growable: true);

    filtered.sort((a, b) {
      if (a.partnerIsBoosted != b.partnerIsBoosted) {
        return a.partnerIsBoosted ? -1 : 1;
      }
      final capacityComparison = (a.capacity ?? 0).compareTo(b.capacity ?? 0);
      if (minimumCapacity != null && capacityComparison != 0) {
        return capacityComparison;
      }
      final priceComparison = a.price.compareTo(b.price);
      if (priceComparison != 0) {
        return priceComparison;
      }
      return a.name.compareTo(b.name);
    });

    return filtered;
  }

  Future<List<PartnerCatalogPrestation>> fetchMealCatalog({
    String? city,
    String? cuisineCategory,
  }) async {
    final tableMeals = await fetchAvailableByService(
      typeService: 'table_resto',
      city: city,
      cuisineCategory: cuisineCategory,
    );
    final deliveryMeals = await fetchAvailableByService(
      typeService: 'plat_livraison',
      city: city,
      cuisineCategory: cuisineCategory,
    );
    return _deduplicatePrestations(<PartnerCatalogPrestation>[
      ...tableMeals,
      ...deliveryMeals,
    ]);
  }

  Future<List<PartnerCatalogPrestation>> fetchActivityCatalog({
    String? city,
  }) async {
    final leisure = await fetchAvailableByService(
      typeService: 'ticket_jeu',
      city: city,
    );
    final cinema = await fetchAvailableByService(
      typeService: 'ticket_cinema',
      city: city,
    );
    return _deduplicatePrestations(<PartnerCatalogPrestation>[
      ...leisure,
      ...cinema,
    ]);
  }

  Future<List<PartnerCatalogPrestation>> fetchFleetCatalog({
    String? city,
  }) {
    return fetchAvailableByService(
      typeService: 'location_voiture',
      city: city,
    );
  }

  Future<List<Hotel>> fetchHotelCatalog({String? city}) async {
    final prestations = await fetchPrestations(typeService: 'chambre_hotel');
    final filtered = prestations
        .where((prestation) => _matchesCity(prestation, city))
        .toList(growable: false);

    final grouped = <String, List<PartnerCatalogPrestation>>{};
    for (final prestation in filtered) {
      grouped
          .putIfAbsent(prestation.partnerId, () => <PartnerCatalogPrestation>[])
          .add(prestation);
    }

    final hotels = grouped.values
        .map((group) => _mapHotelGroup(group, requestedCity: city))
        .toList(growable: false);

    hotels.sort((a, b) {
      if (a.isFeatured != b.isFeatured) {
        return a.isFeatured ? -1 : 1;
      }
      final ratingComparison = b.rating.compareTo(a.rating);
      if (ratingComparison != 0) {
        return ratingComparison;
      }
      return a.name.compareTo(b.name);
    });

    return hotels;
  }

  Future<List<Room>> fetchHotelRooms({
    required String partnerId,
  }) async {
    final prestations = await fetchPrestations(
      typeService: 'chambre_hotel',
      partnerId: partnerId,
    );

    return prestations.map(_mapRoomFromPrestation).toList(growable: false);
  }

  Future<List<PartnerCatalogPrestation>> fetchDeliveryCatalog({
    String? cuisineCategory,
    AppLocation? nearLocation,
  }) async {
    final prestations = await fetchPrestations(typeService: 'plat_livraison');
    final normalizedCuisine = _normalizeLabel(cuisineCategory);

    final filtered = prestations.where((prestation) {
      if (normalizedCuisine == null || normalizedCuisine.isEmpty) {
        return true;
      }
      return _normalizeLabel(prestation.cuisineCategory) == normalizedCuisine;
    }).toList(growable: true);

    filtered.sort((a, b) {
      if (a.partnerIsBoosted != b.partnerIsBoosted) {
        return a.partnerIsBoosted ? -1 : 1;
      }

      if (nearLocation != null) {
        final aCityMatch = _matchesCity(a, nearLocation.city);
        final bCityMatch = _matchesCity(b, nearLocation.city);
        if (aCityMatch != bCityMatch) {
          return aCityMatch ? -1 : 1;
        }

        final aDistance = nearLocation.distanceTo(a.partnerLocation);
        final bDistance = nearLocation.distanceTo(b.partnerLocation);
        final distanceComparison = aDistance.compareTo(bDistance);
        if (distanceComparison != 0) {
          return distanceComparison;
        }
      }

      return a.name.compareTo(b.name);
    });

    return filtered;
  }

  Future<List<CartItem>> synchronizeCartItems(Iterable<CartItem> items) async {
    final currentItems = items.toList(growable: false);
    final prestationIds = currentItems
        .map((item) => item.prestationId)
        .whereType<String>()
        .toSet();

    if (prestationIds.isEmpty) {
      return currentItems;
    }

    final prestations = await fetchPrestationsByIds(prestationIds);
    return currentItems.map((item) {
      final prestationId = item.prestationId;
      if (prestationId == null) {
        return item;
      }

      final prestation = prestations[prestationId];
      if (prestation == null) {
        return item;
      }

      final multiplier =
          (item.metadata['pricingMultiplier'] as num?)?.toInt() ?? 1;
      final latestPrice = prestation.price.round() * multiplier;
      return item.copyWith(
        name: prestation.name,
        priceValue: latestPrice,
        priceDisplay: CartModel.formatCurrency(latestPrice),
        partnerId: prestation.partnerId,
        partnerName: prestation.partnerName,
        partnerType: prestation.partnerType,
        partnerCity: prestation.cityHint ?? item.partnerCity,
        partnerAddress: prestation.partnerLocation.address.isEmpty
            ? item.partnerAddress
            : prestation.partnerLocation.address,
        serviceType: prestation.typeService,
        partnerLatitude: prestation.partnerLocation.latitude,
        partnerLongitude: prestation.partnerLocation.longitude,
        metadata: {
          ...item.metadata,
          'partnerDetails': prestation.details,
          if (prestation.capacity != null) 'capacity': prestation.capacity,
          if (prestation.cuisineCategory != null)
            'cuisineCategory': prestation.cuisineCategory,
        },
      );
    }).toList(growable: false);
  }

  Hotel _mapHotelGroup(
    List<PartnerCatalogPrestation> group, {
    String? requestedCity,
  }) {
    final primary = group.first;
    final roomOffers =
        group.map(_mapRoomFromPrestation).toList(growable: false);

    final imageUrls = _deduplicateUrls(
      group.expand(_extractImageUrls).toList(growable: false),
    );
    final video360Urls = _deduplicateUrls(
      group.expand(_extractVideo360Urls).toList(growable: false),
    );
    final amenities = _deduplicateStrings(
      group
          .expand(
            (prestation) => _readStringList(
              prestation.details['amenities'],
            ),
          )
          .toList(growable: false),
    );

    final fallbackCity = requestedCity?.trim().isNotEmpty == true
        ? requestedCity!.trim()
        : 'Abidjan';
    final address = _readString(primary.details, 'address') ??
        _readString(primary.details, 'adresse') ??
        primary.partnerLocation.address;
    final city = _resolveCity(primary, fallbackCity: fallbackCity);
    final rating = _readDouble(primary.details, 'rating') ??
        _readDouble(primary.details, 'stars') ??
        (primary.partnerIsBoosted ? 4.8 : 4.4);
    final reviewCount = _readInt(primary.details, 'reviewCount') ??
        _readInt(primary.details, 'review_count') ??
        0;
    final description = _readString(primary.details, 'description') ??
        _readString(primary.details, 'summary') ??
        'Prestations hebergement disponibles chez ${primary.partnerName}.';

    final minPrice = group
        .map((prestation) => prestation.price)
        .where((price) => price > 0)
        .fold<double>(0, (current, value) {
      if (current == 0 || value < current) {
        return value;
      }
      return current;
    });

    final capacity = group
        .map((prestation) => prestation.capacity ?? 0)
        .fold<int>(2, (current, value) => value > current ? value : current);

    return Hotel(
      id: primary.partnerId,
      partnerId: primary.partnerId,
      source: 'partner_catalog',
      name: primary.partnerName,
      city: city,
      description: description,
      rating: rating,
      reviewCount: reviewCount,
      pricePerNight: minPrice,
      capacity: capacity,
      address: address.isEmpty ? city : address,
      amenities: amenities.isEmpty
          ? const <String>['WiFi', 'Service premium']
          : amenities,
      latitude: primary.partnerLocation.latitude,
      longitude: primary.partnerLocation.longitude,
      isFeatured: primary.partnerIsBoosted,
      type: primary.partnerType,
      imageUrls: imageUrls.isEmpty
          ? const <String>[
              'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800'
            ]
          : imageUrls,
      video360Urls: video360Urls,
      rooms: roomOffers,
    );
  }

  Room _mapRoomFromPrestation(PartnerCatalogPrestation prestation) {
    final imageUrls = _extractImageUrls(prestation);
    final video360Urls = _extractVideo360Urls(prestation);

    return Room(
      id: prestation.id,
      prestationId: prestation.id,
      hotelId: prestation.partnerId,
      partnerId: prestation.partnerId,
      roomType: prestation.name,
      capacity: prestation.capacity ?? 2,
      price: prestation.price,
      amenities: _readStringList(prestation.details['amenities']),
      available: prestation.isAvailable,
      imageUrls: imageUrls,
      video360Urls: video360Urls,
    );
  }

  bool _matchesCity(PartnerCatalogPrestation prestation, String? city) {
    final normalizedCity = _normalizeLabel(city);
    if (normalizedCity == null || normalizedCity.isEmpty) {
      return true;
    }

    final candidates = <String?>[
      prestation.cityHint,
      _readString(prestation.details, 'city'),
      _readString(prestation.details, 'ville'),
      _readString(prestation.details, 'address'),
      prestation.partnerLocation.city,
      prestation.partnerLocation.address,
    ];

    for (final candidate in candidates) {
      final normalizedCandidate = _normalizeLabel(candidate);
      if (normalizedCandidate == null || normalizedCandidate.isEmpty) {
        continue;
      }
      if (normalizedCandidate == normalizedCity ||
          normalizedCandidate.contains(normalizedCity) ||
          normalizedCity.contains(normalizedCandidate)) {
        return true;
      }
    }

    return false;
  }

  String _resolveCity(
    PartnerCatalogPrestation prestation, {
    required String fallbackCity,
  }) {
    return prestation.cityHint ??
        _readString(prestation.details, 'city') ??
        _readString(prestation.details, 'ville') ??
        prestation.partnerLocation.city ??
        fallbackCity;
  }

  List<String> _extractImageUrls(PartnerCatalogPrestation prestation) {
    final detailImages = <String>[
      ..._readStringList(prestation.details['imageUrls']),
      ..._readStringList(prestation.details['image_urls']),
      ..._readStringList(prestation.details['photos']),
      ..._readStringList(prestation.details['photoUrls']),
    ];
    final mediaImages = prestation.mediaUrls
        .where((url) => !_looksLikeVideoOnlyUrl(url))
        .toList(growable: false);
    return _deduplicateUrls(<String>[
      ...detailImages,
      ...mediaImages,
    ]);
  }

  List<String> _extractVideo360Urls(PartnerCatalogPrestation prestation) {
    final detailVideos = <String>[
      ..._readStringList(prestation.details['video360Urls']),
      ..._readStringList(prestation.details['video_360_urls']),
      ..._readStringList(prestation.details['virtualTourUrls']),
      ..._readStringList(prestation.details['virtual_tour_urls']),
    ];
    final mediaVideos = prestation.mediaUrls
        .where(_looksLikePanoramaUrl)
        .toList(growable: false);
    return _deduplicateUrls(<String>[
      ...detailVideos,
      ...mediaVideos,
    ]);
  }

  List<String> _readStringList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return <String>[raw.trim()];
    }
    return const <String>[];
  }

  String? _readString(Map<String, dynamic> raw, String key) {
    final value = raw[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  double? _readDouble(Map<String, dynamic> raw, String key) {
    final value = raw[key];
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }

  int? _readInt(Map<String, dynamic> raw, String key) {
    final value = raw[key];
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  String? _normalizeLabel(String? raw) {
    if (raw == null) {
      return null;
    }

    final value = raw.trim().toLowerCase();
    if (value.isEmpty) {
      return null;
    }

    return value
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ô', 'o')
        .replaceAll('û', 'u')
        .replaceAll('î', 'i');
  }

  bool _looksLikePanoramaUrl(String raw) {
    final url = raw.toLowerCase();
    return url.contains('360') ||
        url.contains('panorama') ||
        url.contains('virtual-tour') ||
        url.contains('virtual_tour');
  }

  bool _looksLikeVideoOnlyUrl(String raw) {
    final url = raw.toLowerCase();
    return url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('vimeo.com');
  }

  List<String> _deduplicateStrings(List<String> values) {
    final seen = <String>{};
    final normalized = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) {
        continue;
      }
      normalized.add(trimmed);
    }
    return normalized;
  }

  List<String> _deduplicateUrls(List<String> values) {
    return _deduplicateStrings(values);
  }

  List<PartnerCatalogPrestation> _deduplicatePrestations(
    List<PartnerCatalogPrestation> values,
  ) {
    final seen = <String>{};
    final deduped = <PartnerCatalogPrestation>[];
    for (final value in values) {
      if (!seen.add(value.id)) {
        continue;
      }
      deduped.add(value);
    }
    deduped.sort((a, b) {
      if (a.partnerIsBoosted != b.partnerIsBoosted) {
        return a.partnerIsBoosted ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });
    return deduped;
  }
}
