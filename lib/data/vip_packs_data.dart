import 'package:flutter/material.dart';

class VipGift {
  final IconData icon;
  final String title;
  final String description;
  const VipGift(
      {required this.icon,
      required this.title,
      required this.description});
}

class VipPack {
  final String id;
  final String tag;
  final String name;
  final String subtitle;
  final String price;
  final int priceValue;
  final List<VipGift> gifts;
  final Color gradientStart;
  final Color gradientEnd;
  const VipPack({
    required this.id,
    required this.tag,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.priceValue,
    required this.gifts,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

const kVipPacks = [
  VipPack(
    id: 'pack_assinie',
    tag: 'PACK WEEK-END',
    name: 'Évasion Assinie Premium',
    subtitle: 'Chauffeur AR · 1 Nuit Palm Royal · Dîner',
    price: '250 000 FCFA',
    priceValue: 250000,
    gradientStart: Color(0xFFFFD700),
    gradientEnd: Color(0xFFFFA500),
    gifts: [
      VipGift(
        icon: Icons.directions_car,
        title: 'Chauffeur privé aller-retour',
        description: 'Berline de luxe climatisée · Abidjan – Assinie',
      ),
      VipGift(
        icon: Icons.hotel,
        title: '1 Nuit Palm Royal (suite)',
        description: 'Suite avec vue lagon, petit-déjeuner inclus',
      ),
      VipGift(
        icon: Icons.restaurant,
        title: 'Dîner gastronomique pour 2',
        description: 'Menu prestige au restaurant du resort',
      ),
      VipGift(
        icon: Icons.star,
        title: 'Accueil VIP personnalisé',
        description: 'Champagne & cadeaux de bienvenue à l\'arrivée',
      ),
    ],
  ),
  VipPack(
    id: 'pack_bassam',
    tag: 'PACK PATRIMOINE',
    name: 'Grand-Bassam Royal',
    subtitle: 'Chauffeur · Hôtel Colonial · Visite guidée',
    price: '180 000 FCFA',
    priceValue: 180000,
    gradientStart: Color(0xFF6C63FF),
    gradientEnd: Color(0xFF4FC3F7),
    gifts: [
      VipGift(
        icon: Icons.directions_car,
        title: 'Chauffeur privé aller-retour',
        description: 'Berline climatisée · Abidjan – Grand-Bassam',
      ),
      VipGift(
        icon: Icons.hotel,
        title: 'Hôtel Colonial 4★',
        description: '1 nuit en chambre Vue Mer au cœur du patrimoine',
      ),
      VipGift(
        icon: Icons.tour,
        title: 'Visite guidée patrimoniale',
        description: 'Site classé UNESCO avec guide expert privé',
      ),
      VipGift(
        icon: Icons.local_bar,
        title: 'Cocktail de bienvenue',
        description: 'Cocktail signature de l\'hôtel à l\'arrivée',
      ),
    ],
  ),
  VipPack(
    id: 'pack_yamoussoukro',
    tag: 'PACK DÉCOUVERTE',
    name: 'Yamoussoukro Discovery',
    subtitle: 'Chauffeur · 2 Nuits · Basilique · Gastronomie',
    price: '320 000 FCFA',
    priceValue: 320000,
    gradientStart: Color(0xFF43A047),
    gradientEnd: Color(0xFF1DE9B6),
    gifts: [
      VipGift(
        icon: Icons.directions_car,
        title: 'Chauffeur privé aller-retour',
        description: 'Berline de luxe · 4h de trajet depuis Abidjan',
      ),
      VipGift(
        icon: Icons.hotel,
        title: '2 Nuits hôtel 5★',
        description: 'Suite exécutive avec piscine privée',
      ),
      VipGift(
        icon: Icons.account_balance,
        title: 'Visite Basilique Notre-Dame',
        description: 'Accès VIP à la plus grande église du monde',
      ),
      VipGift(
        icon: Icons.restaurant,
        title: 'Déjeuner gastronomique',
        description: 'Restaurant La Rotonde · Menu signature du chef',
      ),
      VipGift(
        icon: Icons.pool,
        title: 'Accès piscine VIP',
        description: 'Journée détente à la piscine olympique de la Fondation',
      ),
    ],
  ),
  VipPack(
    id: 'pack_abidjan_nuit',
    tag: 'PACK SOIRÉE',
    name: 'Nuit Abidjan Prestige',
    subtitle: 'Chauffeur soirée · Suite panoramique · Champagne',
    price: '150 000 FCFA',
    priceValue: 150000,
    gradientStart: Color(0xFFE91E63),
    gradientEnd: Color(0xFFFF6F00),
    gifts: [
      VipGift(
        icon: Icons.directions_car,
        title: 'Chauffeur soirée & nuit',
        description: 'De 20h à 8h · Trajets illimités dans Abidjan',
      ),
      VipGift(
        icon: Icons.hotel,
        title: 'Suite panoramique',
        description: 'Vue lagune Ébrié · Jacuzzi & minibar offert',
      ),
      VipGift(
        icon: Icons.wine_bar,
        title: 'Champagne à l\'arrivée',
        description: 'Bouteille Moët & Chandon offerte',
      ),
      VipGift(
        icon: Icons.room_service,
        title: 'Room service inclus',
        description: 'Carte complète disponible toute la nuit',
      ),
    ],
  ),
];
