import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

import '../models/issued_pack_ticket.dart';
import '../models/location_model.dart';
import 'location_service.dart';
import 'secure_ticket_service.dart';

class PartnerWifiGeofenceService extends ChangeNotifier {
  PartnerWifiGeofenceService({
    required LocationService locationService,
    required SecureTicketService secureTicketService,
  })  : _locationService = locationService,
        _secureTicketService = secureTicketService;

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const MethodChannel _wifiChannel =
      MethodChannel('drift/wifi_ephemeral');
  static const String _storagePrefix = 'drift_wifi_session_';

  final LocationService _locationService;
  final SecureTicketService _secureTicketService;

  final Set<String> _connectedTicketIds = <String>{};
  StreamSubscription<Position>? _positionSubscription;
  List<IssuedPackTicket> _activeTickets = const <IssuedPackTicket>[];

  List<IssuedPackTicket> get activeTickets => _activeTickets;

  Future<void> restorePersistedSessions() async {
    await _secureTicketService.purgeExpiredTickets();
    final stored = await _secureTicketService.readStoredTickets();
    await activateTickets(stored, notify: false);
  }

  Future<void> activateTickets(
    List<IssuedPackTicket> tickets, {
    bool notify = true,
  }) async {
    final previousTickets = _activeTickets;
    final filtered = tickets
        .where((ticket) => ticket.wifiAccess != null)
        .toList(growable: false);
    _activeTickets = filtered;

    if (_activeTickets.isEmpty) {
      for (final ticket in previousTickets) {
        await _purgeStoredCredential(ticket.ticketId);
      }
      await _stopMonitoring();
      if (notify) notifyListeners();
      return;
    }

    final nextTicketIds =
        _activeTickets.map((ticket) => ticket.ticketId).toSet();
    for (final stale in previousTickets.where(
      (ticket) => !nextTicketIds.contains(ticket.ticketId),
    )) {
      await _disconnectAndPurge(stale);
    }

    for (final ticket in _activeTickets) {
      await _storeEncryptedCredential(ticket);
    }

    _startMonitoring();
    await _evaluateCurrentPosition();
    if (notify) notifyListeners();
  }

  Future<void> purgeExpiredSessions() async {
    final now = DateTime.now().toUtc();
    final expired = _activeTickets
        .where((ticket) => !ticket.isActiveAt(now))
        .toList(growable: false);

    for (final ticket in expired) {
      await _disconnectAndPurge(ticket);
    }

    if (expired.isNotEmpty) {
      _activeTickets = _activeTickets
          .where((ticket) => ticket.isActiveAt(now))
          .toList(growable: false);
      notifyListeners();
    }
  }

  Future<void> _evaluateCurrentPosition() async {
    final current = await _locationService.getCurrentLocation();
    if (current == null) return;
    await _handleLocation(current);
  }

  void _startMonitoring() {
    _positionSubscription ??= _locationService.getPositionStream().listen(
      (position) {
        _handleLocation(
          AppLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            address: 'Position actuelle',
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Geofencing wifi error: $error');
      },
    );
  }

  Future<void> _stopMonitoring() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _connectedTicketIds.clear();
  }

  Future<void> _handleLocation(AppLocation currentLocation) async {
    final now = DateTime.now().toUtc();
    final expiredTicketIds = <String>{};

    for (final ticket in _activeTickets) {
      final wifi = ticket.wifiAccess;
      if (wifi == null) continue;

      final partnerLocation = AppLocation(
        latitude: wifi.latitude,
        longitude: wifi.longitude,
        address: wifi.ssid,
      );

      final distanceMeters =
          currentLocation.distanceTo(partnerLocation) * 1000.0;
      final shouldConnect = ticket.isActiveAt(now) && distanceMeters <= 50;
      final isConnected = _connectedTicketIds.contains(ticket.ticketId);

      if (shouldConnect && !isConnected) {
        await _connectWifi(ticket);
        _connectedTicketIds.add(ticket.ticketId);
        notifyListeners();
      } else if (!shouldConnect && isConnected) {
        await _disconnectAndPurge(ticket);
        _connectedTicketIds.remove(ticket.ticketId);
        if (!ticket.isActiveAt(now)) {
          expiredTicketIds.add(ticket.ticketId);
        }
        notifyListeners();
      } else if (!ticket.isActiveAt(now)) {
        await _purgeStoredCredential(ticket.ticketId);
        expiredTicketIds.add(ticket.ticketId);
      }
    }

    if (expiredTicketIds.isNotEmpty) {
      _activeTickets = _activeTickets
          .where((ticket) => !expiredTicketIds.contains(ticket.ticketId))
          .toList(growable: false);
      if (_activeTickets.isEmpty) {
        await _stopMonitoring();
      }
      notifyListeners();
    }
  }

  Future<void> _connectWifi(IssuedPackTicket ticket) async {
    final wifi = ticket.wifiAccess;
    if (wifi == null) return;

    try {
      await _wifiChannel.invokeMethod<void>(
        'connectToProtectedNetwork',
        <String, dynamic>{
          'ssid': wifi.ssid,
          'passwordEncrypted': wifi.passwordEncrypted,
          'ticketId': ticket.ticketId,
        },
      );
    } on MissingPluginException {
      debugPrint(
          'Native Wi-Fi bridge missing, encrypted credentials preserved.');
    } catch (error) {
      debugPrint('Wi-Fi auto-connect failed: $error');
    }
  }

  Future<void> _disconnectAndPurge(IssuedPackTicket ticket) async {
    final wifi = ticket.wifiAccess;
    if (wifi != null) {
      try {
        await _wifiChannel.invokeMethod<void>(
          'disconnectNetwork',
          <String, dynamic>{
            'ssid': wifi.ssid,
            'ticketId': ticket.ticketId,
          },
        );
      } on MissingPluginException {
        debugPrint('Native Wi-Fi bridge missing during disconnect.');
      } catch (error) {
        debugPrint('Wi-Fi disconnect failed: $error');
      }
    }

    await _purgeStoredCredential(ticket.ticketId);
  }

  Future<void> _storeEncryptedCredential(IssuedPackTicket ticket) async {
    final wifi = ticket.wifiAccess;
    if (wifi == null) return;

    await _storage.write(
      key: '$_storagePrefix${ticket.ticketId}',
      value: wifi.passwordEncrypted,
    );
  }

  Future<void> _purgeStoredCredential(String ticketId) async {
    await _storage.delete(key: '$_storagePrefix$ticketId');
  }

  @override
  void dispose() {
    _stopMonitoring();
    super.dispose();
  }
}
