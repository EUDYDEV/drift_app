import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/hotel_model.dart';
import '../models/room_model.dart';
import 'api_service.dart';
import 'partner_catalog_service.dart';

class HotelService extends ChangeNotifier {
  HotelService({PartnerCatalogService? partnerCatalogService})
      : _partnerCatalogService =
            partnerCatalogService ?? PartnerCatalogService();

  final PartnerCatalogService _partnerCatalogService;

  List<Hotel> _hotels = [];
  List<Room> _rooms = [];
  bool _isLoading = false;
  String? _error;

  List<Hotel> get hotels => _hotels;
  List<Room> get rooms => _rooms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<List<Hotel>> searchEstablishments(String query, {String? city}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final all = await getHotelsInCity(city ?? 'Abidjan');
      final queryLower = query.toLowerCase();
      final results = all
          .where(
            (hotel) =>
                hotel.name.toLowerCase().contains(queryLower) ||
                hotel.city.toLowerCase().contains(queryLower),
          )
          .toList(growable: false);

      _isLoading = false;
      notifyListeners();
      return results;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return const <Hotel>[];
    }
  }

  Future<List<Hotel>> getFeaturedEstablishments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final all = await getHotelsInCity('Abidjan');
      final featured = all.where((hotel) => hotel.isFeatured).toList();
      _hotels = featured.isEmpty
          ? all.take(6).toList(growable: false)
          : featured;

      _isLoading = false;
      notifyListeners();
      return _hotels;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return const <Hotel>[];
    }
  }

  Future<List<Hotel>> getHotelsInCity(String city) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      List<Hotel> legacyHotels = const <Hotel>[];
      List<Hotel> partnerHotels = const <Hotel>[];

      try {
        legacyHotels = await _fetchLegacyHotels(city);
      } catch (_) {
        legacyHotels = const <Hotel>[];
      }

      try {
        partnerHotels = await _partnerCatalogService.fetchHotelCatalog(
          city: city,
        );
      } catch (_) {
        partnerHotels = const <Hotel>[];
      }

      if (legacyHotels.isEmpty && partnerHotels.isEmpty) {
        throw Exception('Aucune source d\'hotel disponible');
      }

      _hotels = _mergeHotels(
        preferred: partnerHotels,
        fallback: legacyHotels,
      );
      _isLoading = false;
      notifyListeners();
      return _hotels;
    } catch (e) {
      _error = 'Erreur lors de la recuperation des hotels: $e';
      _isLoading = false;
      notifyListeners();
      return const <Hotel>[];
    }
  }

  Future<List<Room>> getRoomsForHotel(
    String hotelId, {
    String? partnerId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final normalizedPartnerId =
          partnerId != null && partnerId.trim().isNotEmpty
              ? partnerId.trim()
              : null;

      if (normalizedPartnerId != null) {
        final partnerRooms = await _partnerCatalogService.fetchHotelRooms(
          partnerId: normalizedPartnerId,
        );
        if (partnerRooms.isNotEmpty) {
          _rooms = partnerRooms;
          _isLoading = false;
          notifyListeners();
          return _rooms;
        }
      }

      final response = await ApiService.get('/hotels/$hotelId/rooms');
      if (response.statusCode != 200) {
        if (normalizedPartnerId == null) {
          final partnerRooms = await _partnerCatalogService.fetchHotelRooms(
            partnerId: hotelId,
          );
          if (partnerRooms.isNotEmpty) {
            _rooms = partnerRooms;
            _isLoading = false;
            notifyListeners();
            return _rooms;
          }
        }
        throw Exception('Backend error: ${response.statusCode}');
      }

      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      _rooms = data
          .map((room) => Room.fromJson(room as Map<String, dynamic>))
          .toList(growable: false);
      _isLoading = false;
      notifyListeners();
      return _rooms;
    } catch (e) {
      _error = 'Erreur lors de la recuperation des chambres: $e';
      _isLoading = false;
      notifyListeners();
      return const <Room>[];
    }
  }

  Future<bool> reserveRoom({
    required String hotelId,
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      if (hotelId.isEmpty) {
        _error = 'hotelId manquant';
        notifyListeners();
        return false;
      }
      final response = await ApiService.authenticatedPost(
        '/reservations',
        {
          'room_id': roomId,
          'start_date': checkIn.toIso8601String().split('T').first,
          'end_date': checkOut.toIso8601String().split('T').first,
        },
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        _error = 'Utilisateur non authentifie';
        notifyListeners();
        return false;
      }

      if (response.statusCode == 201) {
        _error = null;
        return true;
      }

      _error = 'Reservation refusee: ${response.statusCode} ${response.body}';
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<Hotel>> _fetchLegacyHotels(String city) async {
    final response = await ApiService.get(
      '/hotels?city=${Uri.encodeComponent(city)}',
    );
    if (response.statusCode != 200) {
      throw Exception('Backend error: ${response.statusCode}');
    }

    final List<dynamic> data = json.decode(response.body) as List<dynamic>;
    return data
        .map((hotel) => Hotel.fromJson(hotel as Map<String, dynamic>))
        .toList(growable: false);
  }

  List<Hotel> _mergeHotels({
    required List<Hotel> preferred,
    required List<Hotel> fallback,
  }) {
    final merged = <String, Hotel>{};

    for (final hotel in <Hotel>[...preferred, ...fallback]) {
      final key = hotel.partnerId != null && hotel.partnerId!.trim().isNotEmpty
          ? hotel.partnerId!.trim()
          : '${hotel.name.toLowerCase()}::${hotel.city.toLowerCase()}';
      merged.putIfAbsent(key, () => hotel);
    }

    final hotels = merged.values.toList(growable: false);
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
}
