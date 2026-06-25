import 'package:flutter/foundation.dart';

import '../models/location_model.dart';

class HomeJourneyController extends ChangeNotifier {
  AppLocation? _pendingDestination;

  AppLocation? get pendingDestination => _pendingDestination;

  void rememberDestination(AppLocation destination) {
    _pendingDestination = destination;
    notifyListeners();
  }

  AppLocation? consumeDestination() {
    final destination = _pendingDestination;
    _pendingDestination = null;
    notifyListeners();
    return destination;
  }

  void clear() {
    if (_pendingDestination == null) return;
    _pendingDestination = null;
    notifyListeners();
  }
}
