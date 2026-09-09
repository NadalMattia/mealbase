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

  // Identifica l'app verso Open Food Facts e imposta lingua e paese usati
  // per la ricerca dei prodotti.
  OpenFoodAPIConfiguration.userAgent = UserAgent(
    name: 'MealBase',
    url: 'https://github.com/NadalMattia/mealbase',
  );
  OpenFoodAPIConfiguration.globalLanguages = [OpenFoodFactsLanguage.ITALIAN];
  OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.ITALY;

  await Hive.initFlutter();

  // Gli adapter vanno registrati prima di aprire qualsiasi box.
  HiveService.registerAdapter();
  LocationService.registerAdapter();
  ShoppingListService.registerAdapter();
  HouseService.registerAdapter();

  // I box vanno aperti prima delle notifiche: la sincronizzazione dei
  // promemoria innescata al cambio casa legge i dati da Hive.
  await HouseService.openBox();
  await OnboardingService.openBox();

  await NotificationService().init();

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
        // HouseProvider carica già le case nel proprio costruttore.
        ChangeNotifierProvider(create: (_) => HouseProvider()),
      ],
      child: MaterialApp(
        title: 'MealBase',
        theme: buildAppTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}