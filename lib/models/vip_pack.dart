import 'package:flutter/material.dart';

class VipGift {
  final IconData icon;
  final String title;
  final String description;

  const VipGift({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class VipPack {
  final String id;
  final String name;
  final String subtitle;
  final String tag;
  final String price;
  final int priceValue;
  final Color gradientStart;
  final Color gradientEnd;
  final List<VipGift> gifts;

  const VipPack({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.tag,
    required this.price,
    required this.priceValue,
    required this.gradientStart,
    required this.gradientEnd,
    required this.gifts,
  });
}

// Placeholder list: production should fetch this from backend.
const List<VipPack> kVipPacks = [];
