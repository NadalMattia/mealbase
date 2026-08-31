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
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurazione richiesta dal pacchetto openfoodfacts prima di ogni
  // chiamata: User-Agent e lingua/paese di riferimento per i risultati.
  // Non serve alcun account Open Food Facts: userAgent è solo una stringa
  // identificativa per le richieste HTTP, non una credenziale. Il login
  // (User con userId/password) serve solo per operazioni di scrittura
  // (aggiungere prodotti, caricare immagini), che questa app non usa.
  OpenFoodAPIConfiguration.userAgent = UserAgent(
    name: 'MealBase',
    url: 'https://github.com/NadalMattia/mealbase',
  );
  OpenFoodAPIConfiguration.globalLanguages = [OpenFoodFactsLanguage.ITALIAN];
  OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.ITALY;

  // Inizializza Hive
  await Hive.initFlutter();

  // Registra gli adapter di Hive ma NON apre i box "per casa"
  HiveService.registerAdapter();
  LocationService.registerAdapter();
  ShoppingListService.registerAdapter();
  HouseService.registerAdapter();

  // Il box delle case è globale (non dipende da quale casa è selezionata)
  // quindi, a differenza degli altri, viene aperto subito qui.
  await HouseService.openBox();

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
