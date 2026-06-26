import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'controllers/app_preferences_controller.dart';
import 'controllers/experience_filter_controller.dart';
import 'controllers/home_journey_controller.dart';
import 'controllers/main_navigation_controller.dart';
import 'controllers/pack_journey_controller.dart';
import 'controllers/ride_state_controller.dart';
import 'models/location_model.dart';
import 'screens/admin/it_master_dashboard_page.dart';
import 'screens/auth/login_screen.dart';
import 'screens/driver_mission_screen.dart';
import 'screens/home_screen.dart';
import 'screens/main_navigation_page.dart';
import 'screens/ride_restriction_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/geographic_consistency_service.dart';
import 'services/location_service.dart';
import 'services/partner_catalog_service.dart';
import 'services/partner_wifi_geofence_service.dart';
import 'services/payment_service.dart';
import 'services/secure_ticket_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const DriFtApp());
}

class DriFtApp extends StatelessWidget {
  const DriFtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppPreferencesController()..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => AuthService()..initialize()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        Provider(create: (_) => PartnerCatalogService()),
        Provider(create: (_) => PaymentService()),
        Provider(create: (_) => SecureTicketService()),
        Provider(
          create: (context) => GeographicConsistencyService(
            locationService: context.read<LocationService>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => MainNavigationController()),
        ChangeNotifierProvider(create: (_) => ExperienceFilterController()),
        ChangeNotifierProvider(create: (_) => HomeJourneyController()),
        ChangeNotifierProvider(create: (_) => PackJourneyController()),
        ChangeNotifierProvider(
          create: (_) => RideStateController()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => PartnerWifiGeofenceService(
            locationService: context.read<LocationService>(),
            secureTicketService: context.read<SecureTicketService>(),
          )..restorePersistedSessions(),
        ),
      ],
      child: Consumer<AppPreferencesController>(
        builder: (context, preferences, _) => MaterialApp(
          title: 'DriFt',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: preferences.themeMode,
          locale: preferences.locale,
          supportedLocales: const <Locale>[
            Locale('fr'),
            Locale('en'),
          ],
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const _InitialRouteGate(),
          routes: {
            '/home': (context) => const MainNavigationPage(),
            '/login': (context) => const LoginScreen(),
            '/admin': (context) => const ItMasterDashboardPage(),
            '/admin-dashboard': (context) => const ItMasterDashboardPage(),
            '/driver-mission': (context) => const DriverMissionScreen(),
          },
          builder: (context, child) {
            final rideState = context.watch<RideStateController>();
            if (rideState.isRestricted) {
              return RideRestrictionScreen(
                reason: rideState.restrictionReason,
              );
            }
            return child ?? const SizedBox.shrink();
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/admin' ||
                settings.name?.startsWith('/admin-dashboard') == true) {
              return MaterialPageRoute(
                builder: (context) => const ItMasterDashboardPage(),
              );
            }

            // Gérer les deep links
            if (settings.name?.startsWith('driftapp://location') == true) {
              final uri = Uri.parse(settings.name!);
              final lat = double.tryParse(uri.queryParameters['lat'] ?? '');
              final lon = double.tryParse(uri.queryParameters['lon'] ?? '');
              final address = uri.queryParameters['address'];

              if (lat != null && lon != null && address != null) {
                final location = AppLocation(
                  latitude: lat,
                  longitude: lon,
                  address: address,
                  city: address,
                  country: "Côte d'Ivoire",
                );
                return MaterialPageRoute(
                  builder: (context) => HomeScreen(
                    sharedLocation: location,
                  ),
                );
              }
            }
            return null;
          },
        ),
      ),
    );
  }
}

class _InitialRouteGate extends StatelessWidget {
  const _InitialRouteGate();

  @override
  Widget build(BuildContext context) {
    final hashRoute = Uri.base.fragment.trim();
    if (hashRoute == '/admin' ||
        hashRoute == 'admin' ||
        hashRoute.startsWith('/admin-dashboard') ||
        hashRoute.startsWith('admin-dashboard')) {
      return const ItMasterDashboardPage();
    }

    return const SplashScreen();
  }
}
