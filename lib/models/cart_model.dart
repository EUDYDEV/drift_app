import 'package:flutter/material.dart';

import 'issued_pack_ticket.dart';

class CartItem {
  final String id;
  final String type; // 'hotel', 'chauffeur', 'restaurant'
  final String name;
  final String subtitle;
  final String priceDisplay;
  final int priceValue;
  final Color color;
  final IconData icon;
  final String? groupKey;
  final String? partnerId;
  final String? prestationId;
  final String? partnerName;
  final String? partnerType;
  final String? partnerCity;
  final String? partnerAddress;
  final String? serviceType;
  final double? partnerLatitude;
  final double? partnerLongitude;
  final String? wifiSsid;
  final String? wifiPasswordEncrypted;
  final String? qrTicketId;
  final String? qrToken;
  final DateTime? reservationStart;
  final DateTime? reservationEnd;
  final bool reservationActive;
  final Map<String, dynamic> metadata;

  const CartItem({
    required this.id,
    required this.type,
    required this.name,
    required this.subtitle,
    required this.priceDisplay,
    required this.priceValue,
    required this.color,
    required this.icon,
    this.groupKey,
    this.partnerId,
    this.prestationId,
    this.partnerName,
    this.partnerType,
    this.partnerCity,
    this.partnerAddress,
    this.serviceType,
    this.partnerLatitude,
    this.partnerLongitude,
    this.wifiSsid,
    this.wifiPasswordEncrypted,
    this.qrTicketId,
    this.qrToken,
    this.reservationStart,
    this.reservationEnd,
    this.reservationActive = false,
    this.metadata = const <String, dynamic>{},
  });

  CartItem copyWith({
    String? id,
    String? type,
    String? name,
    String? subtitle,
    String? priceDisplay,
    int? priceValue,
    Color? color,
    IconData? icon,
    String? groupKey,
    String? partnerId,
    String? prestationId,
    String? partnerName,
    String? partnerType,
    String? partnerCity,
    String? partnerAddress,
    String? serviceType,
    double? partnerLatitude,
    double? partnerLongitude,
    String? wifiSsid,
    String? wifiPasswordEncrypted,
    String? qrTicketId,
    String? qrToken,
    DateTime? reservationStart,
    DateTime? reservationEnd,
    bool? reservationActive,
    Map<String, dynamic>? metadata,
  }) {
    return CartItem(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      priceDisplay: priceDisplay ?? this.priceDisplay,
      priceValue: priceValue ?? this.priceValue,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      groupKey: groupKey ?? this.groupKey,
      partnerId: partnerId ?? this.partnerId,
      prestationId: prestationId ?? this.prestationId,
      partnerName: partnerName ?? this.partnerName,
      partnerType: partnerType ?? this.partnerType,
      partnerCity: partnerCity ?? this.partnerCity,
      partnerAddress: partnerAddress ?? this.partnerAddress,
      serviceType: serviceType ?? this.serviceType,
      partnerLatitude: partnerLatitude ?? this.partnerLatitude,
      partnerLongitude: partnerLongitude ?? this.partnerLongitude,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      wifiPasswordEncrypted:
          wifiPasswordEncrypted ?? this.wifiPasswordEncrypted,
      qrTicketId: qrTicketId ?? this.qrTicketId,
      qrToken: qrToken ?? this.qrToken,
      reservationStart: reservationStart ?? this.reservationStart,
      reservationEnd: reservationEnd ?? this.reservationEnd,
      reservationActive: reservationActive ?? this.reservationActive,
      metadata: metadata ?? this.metadata,
    );
  }
}

class CartBudgetSnapshot {
  final int? maxBudget;
  final String? label;
  final int total;

  const CartBudgetSnapshot({
    required this.maxBudget,
    required this.label,
    required this.total,
  });

  int? get remainingBudget => maxBudget == null ? null : maxBudget! - total;

  bool get isOverBudget => maxBudget != null && total > maxBudget!;
}

class CartModel {
  static final ValueNotifier<int> itemCount = ValueNotifier(0);
  static final ValueNotifier<int> revision = ValueNotifier(0);
  static final List<CartItem> items = [];

  static int? _budgetLimit;
  static String? _budgetLabel;

  static void add(CartItem item) {
    final index = items.indexWhere((current) => current.id == item.id);
    if (index >= 0) {
      items[index] = item;
      _notify();
      return;
    }

    items.add(item);
    _notify(countChanged: true);
  }

  static void addAll(Iterable<CartItem> newItems) {
    var changed = false;
    var countChanged = false;

    for (final item in newItems) {
      final index = items.indexWhere((current) => current.id == item.id);
      if (index >= 0) {
        items[index] = item;
      } else {
        items.add(item);
        countChanged = true;
      }
      changed = true;
    }

    if (changed) {
      _notify(countChanged: countChanged);
    }
  }

  static void syncGroup(String groupKey, Iterable<CartItem> groupItems) {
    items.removeWhere((item) => item.groupKey == groupKey);
    items.addAll(groupItems);
    _notify(countChanged: true);
  }

  static void updateItem(
      String id, CartItem Function(CartItem current) update) {
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) return;
    items[index] = update(items[index]);
    _notify();
  }

  static void remove(String id) {
    final before = items.length;
    items.removeWhere((item) => item.id == id);
    if (before != items.length) {
      _notify(countChanged: true);
    }
  }

  static void removeMany(Iterable<String> ids) {
    final idSet = ids.toSet();
    if (idSet.isEmpty) return;

    final before = items.length;
    items.removeWhere((item) => idSet.contains(item.id));
    if (before != items.length) {
      _notify(countChanged: true);
    }
  }

  static void clear() {
    items.clear();
    _notify(countChanged: true);
  }

  static void setBudgetLimit(int? maxBudget, {String? label}) {
    _budgetLimit = maxBudget;
    _budgetLabel = label;
    _notify();
  }

  static int get totalValue =>
      items.fold(0, (sum, item) => sum + item.priceValue);

  static int? get budgetLimit => _budgetLimit;

  static String? get budgetLabel => _budgetLabel;

  static int? get remainingBudget =>
      _budgetLimit == null ? null : _budgetLimit! - totalValue;

  static bool get isOverBudget =>
      _budgetLimit != null && totalValue > _budgetLimit!;

  static CartBudgetSnapshot get budgetSnapshot => CartBudgetSnapshot(
        maxBudget: _budgetLimit,
        label: _budgetLabel,
        total: totalValue,
      );

  static int totalForGroup(String groupKey) => items
      .where((item) => item.groupKey == groupKey)
      .fold(0, (sum, item) => sum + item.priceValue);

  static List<CartItem> itemsForGroup(String groupKey) =>
      items.where((item) => item.groupKey == groupKey).toList(growable: false);

  static List<CartItem> itemsOutsideGroup(String groupKey) => items
      .where((item) => item.groupKey == null || item.groupKey != groupKey)
      .toList(growable: false);

  static List<CartItem> snapshot() => List<CartItem>.unmodifiable(items);

  static List<CartItem> attachIssuedTickets(
    Iterable<IssuedPackTicket> issuedTickets,
  ) {
    final ticketByCartItemId = <String, IssuedPackTicket>{
      for (final ticket in issuedTickets) ticket.cartItemId: ticket,
    };
    if (ticketByCartItemId.isEmpty) {
      return snapshot();
    }

    final now = DateTime.now().toUtc();
    var changed = false;

    for (var index = 0; index < items.length; index++) {
      final current = items[index];
      final ticket = ticketByCartItemId[current.id];
      if (ticket == null) {
        continue;
      }

      items[index] = current.copyWith(
        qrTicketId: ticket.ticketId,
        qrToken: ticket.token,
        reservationStart: ticket.reservationStart ?? current.reservationStart,
        reservationEnd: ticket.reservationEnd ?? current.reservationEnd,
        reservationActive: ticket.isActiveAt(now),
        wifiSsid: ticket.wifiAccess?.ssid ?? current.wifiSsid,
        wifiPasswordEncrypted: ticket.wifiAccess?.passwordEncrypted ??
            current.wifiPasswordEncrypted,
      );
      changed = true;
    }

    if (changed) {
      _notify();
    }

    return snapshot();
  }

  static String get totalFormatted => formatCurrency(totalValue);

  static String formatCurrency(int value) {
    if (value == 0) return '0 FCFA';

    final negative = value < 0;
    final source = value.abs().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < source.length; i++) {
      if (i > 0 && (source.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(source[i]);
    }

    return '${negative ? '-' : ''}${buffer.toString()} FCFA';
  }

  static void _notify({bool countChanged = false}) {
    if (countChanged || itemCount.value != items.length) {
      itemCount.value = items.length;
    }
    revision.value++;
  }
}
