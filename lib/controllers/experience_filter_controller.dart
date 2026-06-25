import 'package:flutter/foundation.dart';

class ExperienceFilterState {
  final String serviceType;
  final String city;

  const ExperienceFilterState({
    required this.serviceType,
    required this.city,
  });
}

class ExperienceFilterController extends ChangeNotifier {
  ExperienceFilterState? _pendingState;

  ExperienceFilterState? consumePendingState() {
    final state = _pendingState;
    _pendingState = null;
    return state;
  }

  void activateHotelFilterForCity(String city) {
    _pendingState = ExperienceFilterState(
      serviceType: 'hotel',
      city: city,
    );
    notifyListeners();
  }
}
