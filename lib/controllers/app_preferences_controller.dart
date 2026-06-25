import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesController extends ChangeNotifier {
  static const _secureStorage = FlutterSecureStorage();

  static const _pushKey = 'drift_push_notifications';
  static const _tripAlertsKey = 'drift_trip_alerts';
  static const _promotionsKey = 'drift_promotional_offers';
  static const _languageKey = 'drift_language';
  static const _darkModeKey = 'drift_dark_mode';
  static const _backgroundLocationKey = 'drift_background_location_sharing';
  static const _partnerHistoryKey = 'drift_partner_trip_history';
  static const _majordomeEnabledKey = 'drift_majordome_enabled';
  static const _temperatureKey = 'drift_majordome_temperature';
  static const _drivingStyleKey = 'drift_majordome_driving_style';
  static const _soundAmbienceKey = 'drift_majordome_sound_ambience';
  static const _instructionsKey = 'drift_majordome_instructions';

  bool _initialized = false;
  bool pushNotifications = true;
  bool tripAlerts = true;
  bool promotionalOffers = false;
  String languageCode = 'fr';
  bool darkMode = false;
  bool backgroundLocationSharing = true;
  bool partnerTripHistoryVisible = false;
  bool majordomeEnabled = false;
  int cabinTemperature = 21;
  String drivingStyle = 'calm';
  String soundAmbience = 'silence';
  String permanentInstructions = '';

  bool get initialized => _initialized;
  Locale get locale => Locale(languageCode);
  ThemeMode get themeMode => darkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> initialize() async {
    if (_initialized) return;
    final preferences = await SharedPreferences.getInstance();
    pushNotifications = preferences.getBool(_pushKey) ?? true;
    tripAlerts = preferences.getBool(_tripAlertsKey) ?? true;
    promotionalOffers = preferences.getBool(_promotionsKey) ?? false;
    languageCode = preferences.getString(_languageKey) ?? 'fr';
    darkMode = preferences.getBool(_darkModeKey) ?? false;
    backgroundLocationSharing =
        preferences.getBool(_backgroundLocationKey) ?? true;
    partnerTripHistoryVisible =
        preferences.getBool(_partnerHistoryKey) ?? false;
    majordomeEnabled = preferences.getBool(_majordomeEnabledKey) ?? false;
    cabinTemperature = preferences.getInt(_temperatureKey) ?? 21;
    drivingStyle = preferences.getString(_drivingStyleKey) ?? 'calm';
    soundAmbience = preferences.getString(_soundAmbienceKey) ?? 'silence';
    permanentInstructions = preferences.getString(_instructionsKey) ?? '';
    _initialized = true;
    notifyListeners();
  }

  Future<void> setPushNotifications(bool value) async {
    pushNotifications = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_pushKey, value);
  }

  Future<void> setTripAlerts(bool value) async {
    tripAlerts = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_tripAlertsKey, value);
  }

  Future<void> setPromotionalOffers(bool value) async {
    promotionalOffers = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_promotionsKey, value);
  }

  Future<void> setLanguage(String value) async {
    if (value != 'fr' && value != 'en') return;
    languageCode = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, value);
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_darkModeKey, value);
  }

  Future<void> setBackgroundLocationSharing(bool value) async {
    backgroundLocationSharing = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_backgroundLocationKey, value);
  }

  Future<void> setPartnerTripHistoryVisible(bool value) async {
    partnerTripHistoryVisible = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_partnerHistoryKey, value);
  }

  Future<void> saveMajordomePreferences({
    required bool enabled,
    required int temperature,
    required String style,
    required String ambience,
    required String instructions,
  }) async {
    majordomeEnabled = enabled;
    cabinTemperature = temperature;
    drivingStyle = style;
    soundAmbience = ambience;
    permanentInstructions = instructions.trim();
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await Future.wait(<Future<bool>>[
      preferences.setBool(_majordomeEnabledKey, enabled),
      preferences.setInt(_temperatureKey, temperature),
      preferences.setString(_drivingStyleKey, style),
      preferences.setString(_soundAmbienceKey, ambience),
      preferences.setString(_instructionsKey, permanentInstructions),
    ]);
  }

  Future<void> deleteNavigationData() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('drift_saved_location');

    final secured = await _secureStorage.readAll();
    final navigationKeys = secured.keys.where(
      (key) =>
          key == 'drift_pack_tickets' ||
          key == 'drift_active_ride_id' ||
          key.startsWith('drift_wifi_session_'),
    );
    for (final key in navigationKeys) {
      await _secureStorage.delete(key: key);
    }
  }
}
