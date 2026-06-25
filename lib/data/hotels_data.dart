// Ce fichier contenait auparavant des jeux de données statiques pour démonstration.
// Il a été neutralisé : l'application doit désormais interroger le backend via
// `HotelService` pour obtenir des hôtels réels. Garder des données fictives
// dans l'app peut provoquer une expérience utilisateur incorrecte.

import '../models/hotel_model.dart';

const List<Map<String, String>> kDestinations = [];

final List<HotelModel> kHotels = [];

List<HotelModel> getHotelsByCity(String city) => [];
