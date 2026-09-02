import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

// Import necessari
import 'providers/pantry_provider.dart';
import 'providers/location_provider.dart';
import 'providers/shopping_list_provider.dart';
import 'providers/house_provider.dart';
import 'services/hive_service.dart';
import 'services/location_service.dart';
import 'services/shopping_list_service.dart';
import 'services/house_service.dart';
import 'services/notification_service.dart';
import 'services/onboarding_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurazione Open Food Facts
  OpenFoodAPIConfiguration.userAgent = UserAgent(
    name: 'MealBase',
    url: 'https://github.com/NadalMattia/mealbase',
  );
  OpenFoodAPIConfiguration.globalLanguages = [OpenFoodFactsLanguage.ITALIAN];
  OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.ITALY;

  // Inizializza Hive
  await Hive.initFlutter();

  // Registra gli adapter di Hive
  HiveService.registerAdapter();
  LocationService.registerAdapter();
  ShoppingListService.registerAdapter();
  HouseService.registerAdapter();

  // Inizializza il servizio di notifiche locali per le scadenze
  await NotificationService().init();

  // Apre il box delle case
  await HouseService.openBox();

  // Apre il box dei flag di onboarding (es. "tip scanner già visto")
  await OnboardingService.openBox();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PantryProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => ShoppingListProvider()),
        ChangeNotifierProvider(create: (_) => HouseProvider()..loadHouses()),
      ],
      child: MaterialApp(
        title: 'MealBase',
        theme: buildAppTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}