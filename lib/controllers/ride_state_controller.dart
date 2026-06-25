import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/driver_model.dart';
import '../models/ride_model.dart';
import '../models/ride_request_details.dart';
import '../services/api_service.dart';
import '../services/driver_availability_service.dart';

class RideStateController extends ChangeNotifier {
  RideStateController._internal();

  static final RideStateController _instance = RideStateController._internal();
  factory RideStateController() => _instance;

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _restrictionFlagKey = 'drift_restriction_active';
  static const String _restrictionReasonKey = 'drift_restriction_reason';
  static const String _activeRideIdKey = 'drift_active_ride_id';

  final DriverAvailabilityService _driverService = DriverAvailabilityService();

  Ride? _activeRide;
  bool _isRestricted = false;
  bool _isProcessing = false;
  bool _initialized = false;
  bool _isRefreshing = false;
  String? _restrictionReason;
  String? _error;
  Timer? _pollingTimer;

  Ride? get activeRide => _activeRide;
  bool get hasActiveRide => _activeRide != null;
  bool get isRestricted => _isRestricted;
  bool get isProcessing => _isProcessing;
  String? get restrictionReason => _restrictionReason;
  String? get error => _error;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _isRestricted = (await _storage.read(key: _restrictionFlagKey)) == 'true';
    _restrictionReason = await _storage.read(key: _restrictionReasonKey);

    await _syncRestrictionWithBackend();

    final activeRideId = await _storage.read(key: _activeRideIdKey);
    if (!_isRestricted && activeRideId != null && activeRideId.isNotEmpty) {
      await refreshRide(activeRideId, persistIfMissing: false);
    }

    notifyListeners();
  }

  Future<Ride> createRideSession({
    required Driver driver,
    required RideRequestDetails request,
  }) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final ride = await _driverService.acceptRideWithDriver(
        driver: driver,
        request: request,
      );
      await _setActiveRide(ride);
      return ride;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<Ride> createSelfDriveSession({
    required RideRequestDetails request,
  }) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final ride = await _driverService.createRideWithoutDriver(
        request: request,
      );
      await _setActiveRide(ride);
      return ride;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<Ride?> refreshActiveRide() async {
    final ride = _activeRide;
    if (ride == null) return null;
    return refreshRide(ride.id);
  }

  Future<Ride?> refreshRide(
    String rideId, {
    bool persistIfMissing = true,
  }) async {
    if (_isRefreshing) return _activeRide;
    _isRefreshing = true;

    try {
      final ride = await _driverService.getRideById(rideId);
      await _applyRide(ride);
      return ride;
    } catch (e) {
      _error = e.toString();
      if (persistIfMissing) {
        notifyListeners();
      }
      return _activeRide;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<bool> cancelActiveRide() async {
    final ride = _activeRide;
    if (ride == null) return false;

    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final cancelledRide = await _driverService.cancelRide(ride.id);
      await _applyRide(cancelledRide);
      await _clearActiveRidePersistence();
      _stopPolling();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<RideSettlementResult?> completeActiveRide() async {
    final ride = _activeRide;
    if (ride == null) return null;

    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _driverService.completeRide(ride.id);
      await _applyRide(result.ride);

      if (result.userRestricted) {
        await _setRestriction(true, result.restrictionReason);
      } else {
        await _clearActiveRidePersistence();
        _stopPolling();
      }

      return result;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> _applyRide(Ride ride) async {
    _activeRide = ride;

    if (ride.isRestricted) {
      await _setRestriction(true, ride.restrictionReason, notify: false);
    }

    if (ride.isTerminal) {
      _stopPolling();
      await _clearActiveRidePersistence();
    } else {
      await _storage.write(key: _activeRideIdKey, value: ride.id);
      _startPolling();
    }

    notifyListeners();
  }

  Future<void> _setActiveRide(Ride ride) async {
    _activeRide = ride;
    await _storage.write(key: _activeRideIdKey, value: ride.id);
    if (!ride.isTerminal) {
      _startPolling();
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        refreshActiveRide();
      },
    );
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _clearActiveRidePersistence() async {
    await _storage.delete(key: _activeRideIdKey);
  }

  Future<void> _syncRestrictionWithBackend() async {
    try {
      final response = await ApiService.authenticatedGet('/auth/me');
      if (response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return;

      await _setRestriction(
        decoded['isRestricted'] as bool? ?? false,
        decoded['restrictionReason'] as String?,
        notify: false,
      );
    } catch (_) {
      // Silent fallback: local persisted state remains the source of truth.
    }
  }

  Future<void> _setRestriction(
    bool restricted,
    String? reason, {
    bool notify = true,
  }) async {
    _isRestricted = restricted;
    _restrictionReason = reason;

    if (restricted) {
      await _storage.write(key: _restrictionFlagKey, value: 'true');
      if (reason != null && reason.isNotEmpty) {
        await _storage.write(key: _restrictionReasonKey, value: reason);
      }
    } else {
      await _storage.delete(key: _restrictionFlagKey);
      await _storage.delete(key: _restrictionReasonKey);
    }

    if (notify) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
