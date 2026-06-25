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

const List<VipPack> kVipPacks = [];
