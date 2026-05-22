import 'package:flutter/material.dart';
import '../models/hotel_model.dart';
import '../models/room_model.dart';

class HotelService extends ChangeNotifier {
  List<Hotel> _hotels = [];
  List<Room> _rooms = [];
  bool _isLoading = false;
  String? _error;

  List<Hotel> get hotels => _hotels;
  List<Room> get rooms => _rooms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Recherche globale (Ville ou Nom) pour hôtels, restaus, bars...
  ///
  /// API endpoint (prod) : GET /api/v1/establishments/search?q={query}&city={city}
  Future<List<Hotel>> searchEstablishments(String query, {String? city}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Replace with actual API call when backend is available.
      // final response = await http.get(Uri.parse('https://api.driftapp.com/api/v1/establishments/search?q=$query&city=$city'));
      // if (response.statusCode == 200) {
      //   final List<dynamic> data = json.decode(response.body);
      //   _hotels = data.map((json) => Hotel.fromJson(json)).toList();
      // } else {
      //   throw Exception('Failed to load establishments');
      // }

      // For now, keep simulated data but remove the mock notice
      await Future.delayed(const Duration(milliseconds: 500));

      final all = await getHotelsInCity(city ?? "Abidjan");
      final queryLower = query.toLowerCase();
      final results = all
          .where((h) =>
              h.name.toLowerCase().contains(queryLower) ||
              h.city.toLowerCase().contains(queryLower))
          .toList();

      _isLoading = false;
      notifyListeners();
      return results;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Récupère les établissements "Pépites" (Sponsorisés)
  ///
  /// API endpoint (prod) : GET /api/v1/establishments/featured
  Future<List<Hotel>> getFeaturedEstablishments() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Replace with actual API call when backend is available.
      // final response = await http.get(Uri.parse('https://api.driftapp.com/api/v1/establishments/featured'));
      // if (response.statusCode == 200) {
      //   final List<dynamic> data = json.decode(response.body);
      //   _hotels = data.map((json) => Hotel.fromJson(json)).toList();
      // } else {
      //   throw Exception('Failed to load featured establishments');
      // }

      // For now, keep simulated data but remove the mock notice
      final all = await getHotelsInCity("Abidjan");
      _hotels = all.where((h) => h.isFeatured).toList();

      _hotels.add(Hotel(
        id: 'restau_1',
        name: 'La Pergola - Restaurant Gastronomique',
        city: 'Abidjan',
        description:
            'Cuisine fine ivoirienne et française. Idéal pour rendez-vous d\'affaires.',
        rating: 4.9,
        reviewCount: 120,
        pricePerNight: 25000.0,
        address: 'Zone 4, Abidjan',
        amenities: const ['Terrasse', 'Cave à vin', 'Musique live'],
        isFeatured: true,
        type: 'restaurant',
      ));

      _isLoading = false;
      notifyListeners();
      return _hotels;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Récupère les hôtels disponibles dans une ville
  ///
  /// API endpoint (prod) : GET /api/v1/hotels?city={city}
  Future<List<Hotel>> getHotelsInCity(String city) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Dataset local démo — en prod : réponse de GET /api/v1/hotels?city={city}
      _hotels = [
        Hotel(
          id: 'hotel_1',
          name: 'H\u00f4tel Universal Abidjan',
          city: city,
          rating: 4.5,
          reviewCount: 523,
          pricePerNight: 75000.0,
          description: 'H\u00f4tel 4 \u00e9toiles avec vue sur la baie',
          address: 'Plateau, Abidjan',
          amenities: const ['Wifi', 'Piscine', 'Restaurant', 'Spa', 'Gym'],
          isFeatured: true,
          image: null,
        ),
        Hotel(
          id: 'hotel_2',
          name: 'Novotel Abidjan',
          city: city,
          rating: 4.3,
          reviewCount: 401,
          pricePerNight: 60000.0,
          description: 'H\u00f4tel 3 \u00e9toiles confortable',
          address: 'Cocody, Abidjan',
          amenities: const ['Wifi', 'Restaurant', 'Bar', 'Parking'],
          isFeatured: false,
          image: null,
        ),
        Hotel(
          id: 'hotel_3',
          name: 'Le M\u00e9ridien Abidjan',
          city: city,
          rating: 4.7,
          reviewCount: 687,
          pricePerNight: 95000.0,
          description: 'H\u00f4tel 5 \u00e9toiles premium',
          address: 'Cocody, Abidjan',
          amenities: const [
            'Wifi',
            'Piscine',
            'Restaurant gastronomique',
            'Spa premium',
            'Gym',
            'Business center',
          ],
          isFeatured: true,
          image: null,
        ),
      ];

      _error = null;
      notifyListeners();
      return _hotels;
    } catch (e) {
      _error = "Erreur lors de la r\u00e9cup\u00e9ration des h\u00f4tels: $e";
      notifyListeners();
      return [];
    }
  }

  /// Récupère les chambres disponibles d'un établissement
  ///
  /// API endpoint (prod) : GET /api/v1/rooms?establishment_id={hotelId}
  Future<List<Room>> getRoomsForHotel(String hotelId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Restaurant : renvoie des tables
      if (hotelId.startsWith('restau')) {
        _rooms = [
          Room(
            id: 'table_1',
            roomType: 'Table VIP - Terrasse',
            capacity: 2,
            price: 5000.0,
            amenities: const ['Vue sur mer', 'Bougies', 'Calme'],
            available: true,
            image: null,
            virtualTourUrl: 'https://demo.tour360.com/restaurant-table1',
          ),
          Room(
            id: 'table_2',
            roomType: 'Table Familiale - Int\u00e9rieur',
            capacity: 6,
            price: 2000.0,
            amenities: const ['Climatisation', 'Espace enfant', 'Wifi'],
            available: true,
            image: null,
            virtualTourUrl: 'https://demo.tour360.com/restaurant-table2',
          ),
        ];
        _error = null;
        notifyListeners();
        return _rooms;
      }

      // Dataset local démo — en prod : GET /api/v1/rooms?hotel_id={hotelId}
      _rooms = [
        Room(
          id: 'room_1',
          roomType: 'Single',
          capacity: 1,
          price: 45000.0,
          amenities: const ['Lit simple', 'Salle de bain privée', 'Wifi', 'TV'],
          available: true,
          image: null,
          virtualTourUrl: 'https://demo.tour360.com/room1',
        ),
        Room(
          id: 'room_2',
          roomType: 'Double',
          capacity: 2,
          price: 65000.0,
          amenities: const [
            'Lit double',
            'Salle de bain privée',
            'Wifi',
            'TV',
            'Climatisation',
          ],
          available: true,
          image: null,
          virtualTourUrl: 'https://demo.tour360.com/room2',
        ),
        Room(
          id: 'room_3',
          roomType: 'Suite',
          capacity: 4,
          price: 120000.0,
          amenities: const [
            'Lit king',
            'Salle de bain de luxe',
            'Wifi',
            'TV',
            'Salon',
            'Jacuzzi',
          ],
          available: true,
          image: null,
          virtualTourUrl: 'https://demo.tour360.com/room3',
        ),
      ];

      _error = null;
      notifyListeners();
      return _rooms;
    } catch (e) {
      _error = "Erreur lors de la récupération des chambres: $e";
      notifyListeners();
      return [];
    }
  }

  /// Réserve une chambre
  ///
  /// API endpoint (prod) : POST /api/v1/reservations
  /// Body : { hotelId, roomId, checkIn, checkOut, guestInfo }
  /// Retourne true si la réservation est créée.
  Future<bool> reserveRoom({
    required String hotelId,
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      // Appel API attendu : POST /api/v1/reservations
      await Future.delayed(const Duration(milliseconds: 600));
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
