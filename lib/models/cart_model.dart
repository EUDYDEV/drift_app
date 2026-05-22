import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String type; // 'hotel', 'chauffeur', 'restaurant'
  final String name;
  final String subtitle;
  final String priceDisplay;
  final int priceValue;
  final Color color;
  final IconData icon;

  const CartItem({
    required this.id,
    required this.type,
    required this.name,
    required this.subtitle,
    required this.priceDisplay,
    required this.priceValue,
    required this.color,
    required this.icon,
  });
}

class CartModel {
  static final ValueNotifier<int> itemCount = ValueNotifier(0);
  static final List<CartItem> items = [];

  static void add(CartItem item) {
    if (!items.any((i) => i.id == item.id)) {
      items.add(item);
      itemCount.value = items.length;
    }
  }

  static void remove(String id) {
    items.removeWhere((i) => i.id == id);
    itemCount.value = items.length;
  }

  static void clear() {
    items.clear();
    itemCount.value = 0;
  }

  static int get totalValue => items.fold(0, (s, i) => s + i.priceValue);

  static String get totalFormatted {
    final n = totalValue;
    if (n == 0) return '0 FCFA';
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${buf.toString()} FCFA';
  }
}
