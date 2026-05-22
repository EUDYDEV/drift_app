# 🚗 DriFt - Refonte Complete - Architecture & Guide

## 📋 Vue d'ensemble

**DriFt** est maintenant une plateforme intégrée de **transport + réservation d'hôtels**, inspirée de **Yango**. 

### Deux flux principaux:

1. **Commander immédiatement** 🏎️
   - GPS en temps réel
   - Choix: avec/sans chauffeur
   - Affichage des prix et ETA
   - Sélection du chauffeur disponible

2. **Réserver pour plus tard** 📅
   - Choix ville + dates
   - Sélection hôtels
   - Sélection chambres
   - Résumé avec prix total

---

## 📁 Structure des fichiers créés

### **1. MODÈLES (lib/models/)**

```
📦 models/
├── location_model.dart           # Position GPS + calcul distance
├── driver_model.dart              # Chauffeur/Véhicule + ETA
├── ride_option_model.dart         # Options trajet (avec/sans chauffeur)
├── ride_model.dart                # Trajet immédiat
├── reservation_model.dart         # Réservation planifiée
├── room_model.dart                # Chambre d'hôtel
├── trip_package_model.dart        # Panier (trajets + hôtels)
└── hotel_model.dart (existant)   # Hôtel
```

**Modèles clés:**

- **Location**: latitude/longitude, adresse, calcul distance Haversine
- **Driver**: info chauffeur, véhicule, rating, ETA
- **RideOption**: prix avec/sans chauffeur, estimation temps
- **Ride**: trajet avec statut (pending, accepted, completed)
- **Room**: chambre d'hôtel avec capacité, équipements
- **Reservation**: réservation complète avec hôtels et trajets

### **2. SERVICES (lib/services/)**

```
📦 services/
├── location_service.dart              # Gestion GPS
├── ride_service.dart                  # Calcul trajets & prix
├── driver_availability_service.dart   # Chauffeurs à proximité
└── hotel_service.dart                 # Gestion hôtels & chambres
```

**Fonctionnalités principales:**

- **LocationService**: 
  - `getCurrentLocation()` - position actuelle
  - `startLocationListener()` - suivi en temps réel
  - `getCoordinatesFromAddress()` - geocoding

- **RideService**:
  - `getRideOptions()` - options avec/sans chauffeur
  - `estimateTravelTime()` - durée estimée
  - `calculatePrice()` - prix basé sur distance

- **DriverAvailabilityService**:
  - `findNearbyDrivers()` - chauffeurs à proximité
  - `acceptRideWithDriver()` - valider trajet
  - `cancelRide()` - annuler trajet

- **HotelService**:
  - `getHotelsInCity()` - liste hôtels par ville
  - `getRoomsForHotel()` - chambres disponibles
  - `reserveRoom()` - réserver chambre

### **3. ÉCRANS (lib/screens/)**

```
📦 screens/
├── home_screen.dart                    # 🏠 PAGE D'ACCUEIL (REFONDÉE)
│                                        # ├─ GPS en temps réel
│                                        # ├─ Champ destination
│                                        # └─ 2 boutons options
│
├── immediate_ride_screen.dart          # 🚗 COMMANDE IMMÉDIATE
│                                        # ├─ Récapitulatif trajet
│                                        # ├─ Choix avec/sans chauffeur
│                                        # └─ Affichage prix
│
├── driver_availability_screen.dart     # 👨‍💼 CHAUFFEURS DISPONIBLES
│                                        # ├─ Liste chauffeurs proches
│                                        # ├─ ETA en minutes
│                                        # └─ Sélection & confirmation
│
├── reservation_screen.dart             # 📅 RÉSERVATION ÉTAPE 1
│                                        # ├─ Ville destination
│                                        # ├─ Date départ
│                                        # └─ Date retour (optionnel)
│
├── reservation_date_screen.dart        # 🏨 RÉSERVATION ÉTAPE 2
│                                        # ├─ Liste hôtels disponibles
│                                        # ├─ Affichage prix total
│                                        # └─ Sélection hôtel
│
├── hotel_selection_screen.dart         # 🛏️ RÉSERVATION ÉTAPE 3
│                                        # ├─ Liste chambres
│                                        # ├─ Sélecteur quantité
│                                        # └─ Calcul prix par chambre
│
└── booking_summary_screen.dart         # ✅ RÉSUMÉ FINAL
                                         # ├─ Récapitulatif complet
                                         # ├─ Prix détaillé
                                         # └─ Bouton confirmation
```

---

## 🎯 Flux utilisateur détaillé

### **FLUX 1: COMMANDER IMMÉDIATEMENT** 🏎️

```
1. HomeScreen
   ↓ (Utilisateur tape destination + clique "Commander immédiatement")
2. ImmediateRideScreen
   ├─ Affiche options: "Avec chauffeur" (prix: 2.5€/km) vs "Sans chauffeur" (1.8€/km)
   ├─ Temps estimé (ex: 15-20 min)
   ↓ (Utilisateur sélectionne option + clique "Rechercher")
3. DriverAvailabilityScreen
   ├─ Affiche liste chauffeurs à proximité
   ├─ Nom, rating, véhicule, ETA (ex: 3 min)
   ├─ Numéro téléphone
   ↓ (Utilisateur sélectionne chauffeur + clique "Confirmer")
4. Dialog confirmation
   └─ "Trajet confirmé! Arrivée: 3 minutes"
```

### **FLUX 2: RÉSERVER POUR PLUS TARD** 📅

```
1. HomeScreen
   ↓ (Utilisateur clique "Réserver pour plus tard")
2. ReservationScreen
   ├─ Champ "Quelle ville?" (ex: Yamoussoukro)
   ├─ Date départ
   ├─ Date retour (optionnel)
   ↓ (Utilisateur remplit + clique "Continuer")
3. ReservationDateScreen
   ├─ Affiche hôtels disponibles dans la ville
   ├─ Chaque hôtel: nom, rating, prix total pour la période
   ↓ (Utilisateur sélectionne hôtel)
4. HotelSelectionScreen
   ├─ Liste chambres: Single/Double/Suite
   ├─ Capacité (1-4 personnes)
   ├─ Amenities (Wifi, AC, etc)
   ├─ Sélecteur quantité (+ / -)
   ├─ Calcul prix automatique
   ↓ (Utilisateur ajoute chambres + clique "Continuer")
5. BookingSummaryScreen
   ├─ Récapitulatif complet
   ├─ Hôtel + adresse + rating
   ├─ Dates d'arrivée/départ
   ├─ Chambres sélectionnées avec prix
   ├─ Prix total
   ↓ (Utilisateur clique "Confirmer la réservation")
6. Dialog confirmation
   └─ "Réservation confirmée! Email envoyé."
```

---

## 🔧 Configuration & Installation

### **1. Dépendances dans pubspec.yaml**

Les dépendances actuelles suffisent. Prochainement, ajouter:

```yaml
dependencies:
  # GPS en production
  geolocator: ^10.0.0
  geocoding: ^2.1.0
  
  # Maps
  google_maps_flutter: ^2.5.0
  
  # API HTTP
  http: ^1.1.0
  
  # State management (optionnel)
  provider: ^6.0.0
  
  # Base de données
  supabase_flutter: ^1.0.0  # ou Firebase
  
  # Paiements
  stripe_flutter: ^10.0.0
```

### **2. Mise à jour main.dart** ✅

Déjà fait! L'app démarre maintenant sur **HomeScreen** au lieu de **SplashScreen**.

### **3. Assets & Images**

À ajouter à `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
```

---

## 📊 Modèles de données principaux

### **RideType (Enum)**
```dart
enum RideType { withDriver, withoutDriver }
```

### **RideStatus (Enum)**
```dart
enum RideStatus { pending, accepted, inProgress, completed, cancelled }
```

### **ReservationStatus (Enum)**
```dart
enum ReservationStatus { pending, confirmed, cancelled, completed }
```

### **DriverStatus (Enum)**
```dart
enum DriverStatus { available, busy, offline }
```

---

## 🚀 Prochaines étapes

### **PHASE 2: Intégration Backend**

1. **API Backend** (Node.js/Django/Laravel)
   - Endpoints trajet (création, acceptation, suivi)
   - Endpoints hôtel (liste, réservation)
   - Endpoints chauffeur (localisation, disponibilité)
   - Authentification utilisateur

2. **Remplacement des Mocks**
   - `LocationService` → Intégrer **geolocator**
   - `RideService` → API vraie
   - `DriverAvailabilityService` → WebSocket pour temps réel
   - `HotelService` → API vraie

3. **Base de données**
   - Utilisateurs
   - Trajets (rides)
   - Réservations
   - Hôtels & Chambres
   - Chauffeurs

### **PHASE 3: Paiement**

- Intégrer **Stripe/PayPal/Mobile Money**
- Ajouter gestion portefeuille

### **PHASE 4: Fonctionnalités avancées**

- Historique trajets/réservations
- Notifications push
- Chat avec chauffeur
- Avis & ratings
- Programme de fidélité

---

## 💡 Notes importantes

### **Calcul de distance (Haversine)**
```
Distance = 6371 × arccos(sin(lat1) × sin(lat2) + cos(lat1) × cos(lat2) × cos(lon2 - lon1))
```
Utilisé pour estimer trajets et trouver chauffeurs à proximité.

### **Simulation actuellement**
- GPS retourne une position fixe d'Abidjan
- Chauffeurs générés aléatoirement
- Hôtels/chambres en mock
- Pas d'authentification

### **Tarification démo**
```
Avec chauffeur: 1000 FCFA base + 2.5 FCFA/km
Sans chauffeur: 1000 FCFA base + 1.8 FCFA/km
Hôtel: 45 000 - 95 000 FCFA/nuit
Chambre: 45 000 - 120 000 FCFA/nuit
```

---

## 🎨 Thème & Couleurs

```dart
// Couleur primaire (Bleu)
Color primaryBlue = Color(0xFF1E90FF)  // Trajets

// Couleur secondaire (Vert)
Color secondaryGreen = Color(0xFF00B894)  // Réservations

// Icônes
Icons.directions_car     // Trajet
Icons.calendar_today     // Réservation
Icons.location_on        // GPS
Icons.schedule           // ETA/Temps
Icons.star              // Rating
```

---

## 🧪 Tests recommandés

1. **Tests d'interface**
   - Navigation entre écrans
   - Validation formulaires
   - Affichage dynamique prix

2. **Tests métier**
   - Calcul distance & prix
   - Filtrage chauffeurs
   - Calcul nuits & prix hôtels

3. **Tests e2e**
   - Flux complet: Accueil → Chauffeur
   - Flux complet: Accueil → Réservation

---

## 📝 Exemple d'utilisation - CODE

### **Utiliser LocationService**
```dart
final locationService = LocationService();
final currentLocation = await locationService.getCurrentLocation();
print('Position: ${currentLocation.latitude}, ${currentLocation.longitude}');

// Écouter position en temps réel
locationService.startLocationListener();
```

### **Utiliser RideService**
```dart
final rideService = RideService();
final options = await rideService.getRideOptions(
  from: currentLocation,
  to: destinationLocation,
);

print('Option 1: ${options[0].label} - ${options[0].price} FCFA');
print('Option 2: ${options[1].label} - ${options[1].price} FCFA');
```

### **Utiliser DriverAvailabilityService**
```dart
final driverService = DriverAvailabilityService();
final drivers = await driverService.findNearbyDrivers(
  location: currentLocation,
  radiusKm: 5.0,
);

drivers.forEach((driver) {
  print('${driver.name} - ETA: ${driver.eta} min - Rating: ${driver.rating}');
});
```

### **Utiliser HotelService**
```dart
final hotelService = HotelService();
final hotels = await hotelService.getHotelsInCity('Yamoussoukro');

final rooms = await hotelService.getRoomsForHotel(hotels.first.id);
rooms.forEach((room) {
  print('${room.roomType}: ${room.price} FCFA/nuit');
});
```

---

## 🐛 Dépannage

### **Erreur: "Widget not mounted"**
→ Vérifier `if (mounted)` avant `setState()`

### **ETA toujours 0**
→ Données mock. À remplacer avec API vraie.

### **Chambres ne s'ajoutent pas**
→ Vérifier `_toggleRoom()` et calcul du total

### **GPS ne fonctionne pas**
→ Intégrer `geolocator` en Phase 2

---

## 📞 Support & Contact

Pour questions sur l'architecture:
- Modèles: Voir commentaires dans les fichiers
- Services: Cf. docstrings des fonctions
- Écrans: Cf. inline comments

**Bon développement! 🚀**
