import 'package:drift_app/controllers/app_preferences_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('theme and language changes are persisted', () async {
    final controller = AppPreferencesController();
    await controller.initialize();

    await controller.setDarkMode(true);
    await controller.setLanguage('en');

    final preferences = await SharedPreferences.getInstance();
    expect(controller.darkMode, isTrue);
    expect(controller.languageCode, 'en');
    expect(preferences.getBool('drift_dark_mode'), isTrue);
    expect(preferences.getString('drift_language'), 'en');
  });

  test('notification preferences are independent', () async {
    final controller = AppPreferencesController();
    await controller.initialize();

    await controller.setPushNotifications(false);
    await controller.setTripAlerts(true);
    await controller.setPromotionalOffers(true);

    expect(controller.pushNotifications, isFalse);
    expect(controller.tripAlerts, isTrue);
    expect(controller.promotionalOffers, isTrue);
  });

  test('majordome preferences are saved as one configuration', () async {
    final controller = AppPreferencesController();
    await controller.initialize();

    await controller.saveMajordomePreferences(
      enabled: true,
      temperature: 23,
      style: 'standard',
      ambience: 'lounge',
      instructions: 'Prévoir une bouteille d’eau',
    );

    expect(controller.majordomeEnabled, isTrue);
    expect(controller.cabinTemperature, 23);
    expect(controller.drivingStyle, 'standard');
    expect(controller.soundAmbience, 'lounge');
    expect(
      controller.permanentInstructions,
      'Prévoir une bouteille d’eau',
    );
  });
}
