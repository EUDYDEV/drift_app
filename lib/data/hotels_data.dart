import '../models/hotel_model.dart';
import '../models/room_model.dart';

// ─── Destinations avec vraies photos de Côte d'Ivoire ────────────────────────
const List<Map<String, String>> kDestinations = [
  {
    'name': 'Abidjan',
    'url':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/Abidjan_Plateau.jpg/800px-Abidjan_Plateau.jpg',
    'emoji': '🌆',
  },
  {
    'name': 'Assinie',
    'url':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cb/Assinie_Mafia.jpg/800px-Assinie_Mafia.jpg',
    'emoji': '🏖️',
  },
  {
    'name': 'Yamoussoukro',
    'url':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b2/Basilica_of_Our_Lady_of_Peace_of_Yamoussoukro_01.jpg/800px-Basilica_of_Our_Lady_of_Peace_of_Yamoussoukro_01.jpg',
    'emoji': '⛪',
  },
  {
    'name': 'Grand-Bassam',
    'url':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/6/62/Palais_du_Gouverneur_Grand-Bassam.jpg/800px-Palais_du_Gouverneur_Grand-Bassam.jpg',
    'emoji': '🏛️',
  },
  {
    'name': 'San-Pédro',
    'url':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Baie_des_Sir%C3%A8nes.jpg/800px-Baie_des_Sir%C3%A8nes.jpg',
    'emoji': '🌊',
  },
  {
    'name': 'Korhogo',
    'url':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3c/Mosqu%C3%A9e_de_Kong.jpg/800px-Mosqu%C3%A9e_de_Kong.jpg',
    'emoji': '🌿',
  },
  {
    'name': 'Bouaké',
    'url':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/Cath%C3%A9drale_Sainte-Th%C3%A9r%C3%A8se_de_l%27Enfant_J%C3%A9sus_de_Bouak%C3%A9.jpg/800px-Cath%C3%A9drale_Sainte-Th%C3%A9r%C3%A8se_de_l%27Enfant_J%C3%A9sus_de_Bouak%C3%A9.jpg',
    'emoji': '🏙️',
  },
];

// ─── Hôtels avec photos thématiques réalistes ──────────────────────────────
final List<HotelModel> kHotels = [
  HotelModel(
    id: 'hotel_ivoire',
    name: 'Hôtel Ivoire',
    city: 'Abidjan',
    location: 'Cocody, Abidjan',
    description:
        'Icône de l\'hospitalité abidjanaise depuis 1963, l\'Hôtel Ivoire offre une vue panoramique sur la lagune Ébrié. Une expérience de luxe inégalée au cœur d\'Abidjan.',
    rating: 4.8,
    stars: 5,
    priceDisplay: '85 000 FCFA',
    priceValue: 85000,
    category: 'LUXE',
    imageSeeds: [
      'https://images.unsplash.com/photo-1582719478250-c89d14560382?w=800&q=80',
      'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=800&q=80',
      'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&q=80',
      'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=800&q=80',
    ],
    amenities: ['Piscine', 'Spa', 'WiFi', 'Restaurant', 'Bar', 'Gym', 'Casino'],
    rooms: [
      RoomModel(
        id: 'ivoire_standard',
        name: 'Chambre Standard',
        priceDisplay: '85 000 FCFA / nuit',
        priceValue: 85000,
        imageSeed:
            'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=800&q=80',
        gallerySeeds: [
          'https://images.unsplash.com/photo-1582719478250-c89d14560382?w=800&q=80',
          'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=800&q=80',
          'https://images.unsplash.com/photo-1505693314120-0d443867891c?w=800&q=80',
        ],
      ),
      RoomModel(
        id: 'ivoire_deluxe',
        name: 'Chambre Deluxe Lagune',
        priceDisplay: '120 000 FCFA / nuit',
        priceValue: 120000,
        imageSeed:
            'https://images.unsplash.com/photo-1505692952047-1a78307da8f2?w=800&q=80',
        gallerySeeds: [
          'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=800&q=80',
          'https://images.unsplash.com/photo-1582719478250-c89d14560382?w=800&q=80',
          'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=800&q=80',
        ],
      ),
      RoomModel(
        id: 'ivoire_suite',
        name: 'Suite Senior',
        priceDisplay: '250 000 FCFA / nuit',
        priceValue: 250000,
        imageSeed:
            'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=800&q=80',
        gallerySeeds: [
          'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=800&q=80',
          'https://images.unsplash.com/photo-1582719478250-c89d14560382?w=800&q=80',
          'https://images.unsplash.com/photo-1505692952047-1a78307da8f2?w=800&q=80',
        ],
      ),
    ],
  ),
  HotelModel(
    id: 'sofitel_abidjan',
    name: 'Sofitel Abidjan',
    city: 'Abidjan',
    location: 'Plateau, Abidjan',
    description:
        'Au cœur du quartier des affaires du Plateau, le Sofitel Abidjan incarne l\'élégance française en terre ivoirienne. Chaque détail est pensé pour votre confort absolu.',
    rating: 4.7,
    stars: 5,
    priceDisplay: '120 000 FCFA',
    priceValue: 120000,
    category: 'PREMIUM',
    imageSeeds: [
      'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&q=80',
      'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=800&q=80',
      'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=800&q=80',
      'https://images.unsplash.com/photo-1505692952047-1a78307da8f2?w=800&q=80',
    ],
    amenities: [
      'Piscine',
      'Spa',
      'WiFi',
      'Restaurant Gastronomique',
      'Bar Rooftop',
      'Salle de conférence'
    ],
    rooms: [
      RoomModel(
        id: 'sofitel_superior',
        name: 'Chambre Supérieure',
        priceDisplay: '120 000 FCFA / nuit',
        priceValue: 120000,
        imageSeed:
            'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=800&q=80',
        gallerySeeds: [
          'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=800&q=80',
          'https://images.unsplash.com/photo-1505692952047-1a78307da8f2?w=800&q=80',
          'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&q=80',
        ],
      ),
      RoomModel(
        id: 'sofitel_prestige',
        name: 'Suite Prestige',
        priceDisplay: '320 000 FCFA / nuit',
        priceValue: 320000,
        imageSeed:
            'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=800&q=80',
        gallerySeeds: [
          'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=800&q=80',
          'https://images.unsplash.com/photo-1505692952047-1a78307da8f2?w=800&q=80',
          'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&q=80',
        ],
      ),
    ],
  ),
  HotelModel(
    id: 'palm_royal_assinie',
    name: 'La Palm Royal Beach',
    city: 'Assinie',
    location: 'Assinie-Mafia',
    description:
        'Nichée entre la lagune et l\'océan Atlantique, La Palm Royal Beach est un paradis tropical à deux heures d\'Abidjan. Bungalows sur pilotis, piscine à débordement et cuisine de mer fraîche.',
    rating: 4.6,
    stars: 4,
    priceDisplay: '65 000 FCFA',
    priceValue: 65000,
    category: 'CONFORT',
    imageSeeds: [
      'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?w=800&q=80',
      'https://images.unsplash.com/photo-1587061949409-02df41d5e562?w=800&q=80',
      'https://images.unsplash.com/photo-1439130490301-25e322d88054?w=800&q=80',
      'https://images.unsplash.com/photo-1540202403-b7abd6d5afa1?w=800&q=80',
    ],
    amenities: [
      'Plage privée',
      'Piscine',
      'WiFi',
      'Restaurant Poissons',
      'Water sports',
      'Ponton'
    ],
    rooms: [
      RoomModel(
        id: 'palm_bungalow',
        name: 'Bungalow Jardin',
        priceDisplay: '65 000 FCFA / nuit',
        priceValue: 65000,
        imageSeed:
            'https://images.unsplash.com/photo-1587061949409-02df41d5e562?w=800&q=80',
        gallerySeeds: [
          'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?w=800&q=80',
          'https://images.unsplash.com/photo-1439130490301-25e322d88054?w=800&q=80',
          'https://images.unsplash.com/photo-1540202403-b7abd6d5afa1?w=800&q=80',
        ],
      ),
      RoomModel(
        id: 'palm_bungalow_lagoon',
        name: 'Bungalow Lagune',
        priceDisplay: '95 000 FCFA / nuit',
        priceValue: 95000,
        imageSeed:
            'https://images.unsplash.com/photo-1439130490301-25e322d88054?w=800&q=80',
        gallerySeeds: [
          'https://images.unsplash.com/photo-1587061949409-02df41d5e562?w=800&q=80',
          'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?w=800&q=80',
          'https://images.unsplash.com/photo-1540202403-b7abd6d5afa1?w=800&q=80',
        ],
      ),
    ],
  ),
  HotelModel(
    id: 'bassam_heritage',
    name: 'Bassam Heritage Hotel',
    city: 'Grand-Bassam',
    location: 'Quartier France, Grand-Bassam',
    description:
        'Classé au patrimoine mondial de l\'UNESCO, Grand-Bassam vous accueille dans cet hôtel colonial entièrement restauré. Architecture Belle Époque, piscine ombragée et accès direct à la plage.',
    rating: 4.4,
    stars: 4,
    priceDisplay: '45 000 FCFA',
    priceValue: 45000,
    category: 'STANDARD',
    imageSeeds: [
      'https://images.unsplash.com/photo-1568084680786-a84f91d1153c?w=800&q=80',
      'https://images.unsplash.com/photo-1538356111053-748a48e1acb8?w=800&q=80',
      'https://images.unsplash.com/photo-1552508744-1696d4464960?w=800&q=80',
      'https://images.unsplash.com/photo-1582719478250-c89d14560382?w=800&q=80',
    ],
    amenities: [
      'Plage',
      'Piscine',
      'WiFi',
      'Restaurant colonial',
      'Bar',
      'Visite guidée'
    ],
    rooms: [
      RoomModel(
        id: 'bassam_colonial',
        name: 'Chambre Coloniale',
        priceDisplay: '45 000 FCFA / nuit',
        priceValue: 45000,
        imageSeed:
            'https://images.unsplash.com/photo-1538356111053-748a48e1acb8?w=800&q=80',
        gallerySeeds: [
          'https://images.unsplash.com/photo-1568084680786-a84f91d1153c?w=800&q=80',
          'https://images.unsplash.com/photo-1552508744-1696d4464960?w=800&q=80',
          'https://images.unsplash.com/photo-1582719478250-c89d14560382?w=800&q=80',
        ],
      ),
      RoomModel(
        id: 'bassam_suite',
        name: 'Suite Patrimoine',
        priceDisplay: '75 000 FCFA / nuit',
        priceValue: 75000,
        imageSeed:
            'https://images.unsplash.com/photo-1552508744-1696d4464960?w=800&q=80',
        gallerySeeds: [
          'https://images.unsplash.com/photo-1538356111053-748a48e1acb8?w=800&q=80',
          'https://images.unsplash.com/photo-1568084680786-a84f91d1153c?w=800&q=80',
          'https://images.unsplash.com/photo-1582719478250-c89d14560382?w=800&q=80',
        ],
      ),
    ],
  ),
  HotelModel(
    id: 'president_yamoussoukro',
    name: 'Hôtel Président',
    city: 'Yamoussoukro',
    location: 'Centre, Yamoussoukro',
    description:
        'Face à la Basilique Notre-Dame de la Paix, l\'Hôtel Président offre un cadre solennel et raffiné dans la capitale politique de la Côte d\'Ivoire.',
    rating: 4.3,
    stars: 4,
    priceDisplay: '55 000 FCFA',
    priceValue: 55000,
    category: 'CONFORT',
    imageSeeds: [
      'https://images.unsplash.com/photo-1542314831-c6a4d27ce66b?w=800&q=80',
      'https://images.unsplash.com/photo-1505692952047-1a78307da8f2?w=800&q=80',
      'https://images.unsplash.com/photo-1582719478250-c89d14560382?w=800&q=80',
      'https://images.unsplash.com/photo-1568084680786-a84f91d1153c?w=800&q=80',
    ],
    amenities: [
      'WiFi',
      'Piscine',
      'Restaurant',
      'Salle de conférence',
      'Parking'
    ],
    rooms: [
      RoomModel(
        id: 'president_standard',
        name: 'Chambre Standard',
        priceDisplay: '55 000 FCFA / nuit',
        priceValue: 55000,
        imageSeed:
            'https://images.unsplash.com/photo-1505692952047-1a78307da8f2?w=800&q=80',
        gallerySeeds: [
          'https://images.unsplash.com/photo-1542314831-c6a4d27ce66b?w=800&q=80',
          'https://images.unsplash.com/photo-1582719478250-c89d14560382?w=800&q=80',
          'https://images.unsplash.com/photo-1568084680786-a84f91d1153c?w=800&q=80',
        ],
      ),
    ],
  ),
];

List<HotelModel> getHotelsByCity(String city) =>
    kHotels.where((h) => h.city == city).toList();
