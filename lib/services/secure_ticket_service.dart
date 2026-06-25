import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/cart_model.dart';
import '../models/issued_pack_ticket.dart';
import 'api_service.dart';
import 'auth_service.dart';

class SecureTicketService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _storageKey = 'drift_pack_tickets';

  String buildQrPayload(IssuedPackTicket ticket) => ticket.token;

  List<CartItem> hydrateCartItemsWithTickets({
    required List<CartItem> items,
    required List<IssuedPackTicket> tickets,
  }) {
    final ticketByCartItemId = <String, IssuedPackTicket>{
      for (final ticket in tickets) ticket.cartItemId: ticket,
    };
    final now = DateTime.now().toUtc();

    return items.map((item) {
      final ticket = ticketByCartItemId[item.id];
      if (ticket == null) {
        return item;
      }

      return item.copyWith(
        qrTicketId: ticket.ticketId,
        qrToken: ticket.token,
        reservationStart: ticket.reservationStart ?? item.reservationStart,
        reservationEnd: ticket.reservationEnd ?? item.reservationEnd,
        reservationActive: ticket.isActiveAt(now),
        wifiSsid: ticket.wifiAccess?.ssid ?? item.wifiSsid,
        wifiPasswordEncrypted:
            ticket.wifiAccess?.passwordEncrypted ?? item.wifiPasswordEncrypted,
      );
    }).toList(growable: false);
  }

  Future<List<IssuedPackTicket>> issueTickets({
    required List<CartItem> items,
    required AuthService authService,
  }) async {
    final token = await authService.getToken();
    if (token == null || items.isEmpty) {
      return const <IssuedPackTicket>[];
    }

    final payload = {
      'items': items
          .map(
            (item) => {
              'cartItemId': item.id,
              'prestationId': item.prestationId,
              'partnerId': item.partnerId,
              'serviceType': item.serviceType ?? item.type,
              'name': item.name,
              'reservationStart':
                  item.reservationStart?.toUtc().toIso8601String(),
              'reservationEnd': item.reservationEnd?.toUtc().toIso8601String(),
            },
          )
          .toList(growable: false),
    };

    final response = await ApiService.post(
      '/pack/tickets/issue',
      payload,
      token: token,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Emission des tickets impossible (${response.statusCode}) ${response.body}',
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          'Expected JSON object for pack ticket response');
    }

    final rawTickets = decoded['tickets'];
    if (rawTickets is! List) {
      throw const FormatException('Expected tickets list');
    }

    final issued = rawTickets
        .map(
          (ticket) => IssuedPackTicket.fromJson(
            ticket as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);

    final existing = await readStoredTickets();
    final merged = <String, IssuedPackTicket>{
      for (final ticket in existing) ticket.ticketId: ticket,
      for (final ticket in issued) ticket.ticketId: ticket,
    };
    await _persistTickets(merged.values.toList(growable: false));
    return issued;
  }

  Future<List<IssuedPackTicket>> readStoredTickets() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.isEmpty) {
      return const <IssuedPackTicket>[];
    }

    final decoded = json.decode(raw);
    if (decoded is! List) {
      return const <IssuedPackTicket>[];
    }

    return decoded
        .map(
          (ticket) => IssuedPackTicket.fromJson(
            (ticket as Map).cast<String, dynamic>(),
          ),
        )
        .toList(growable: false);
  }

  Future<void> purgeExpiredTickets() async {
    final now = DateTime.now().toUtc();
    final active = (await readStoredTickets())
        .where((ticket) => ticket.expiresAt.isAfter(now))
        .toList(growable: false);
    await _persistTickets(active);
  }

  Future<void> _persistTickets(List<IssuedPackTicket> tickets) async {
    if (tickets.isEmpty) {
      await _storage.delete(key: _storageKey);
      return;
    }

    final encoded = json.encode(
      tickets.map((ticket) => ticket.toJson()).toList(growable: false),
    );
    await _storage.write(key: _storageKey, value: encoded);
  }
}
