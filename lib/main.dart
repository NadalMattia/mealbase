import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Import necessari
import 'providers/pantry_provider.dart';
import 'providers/location_provider.dart';
import 'providers/shopping_list_provider.dart';
import 'services/hive_service.dart';
import 'services/location_service.dart';
import 'services/shopping_list_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza Hive
  await Hive.initFlutter();

  // Registra gli adapter di Hive ma NON apre i box
  HiveService.registerAdapter();
  LocationService.registerAdapter();
  ShoppingListService.registerAdapter();

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
      ],
      child: MaterialApp(
        title: 'MealBase',
        theme: ThemeData(primarySwatch: Colors.teal),
        home: const HomeScreen(),
      ),
    );
  }
}