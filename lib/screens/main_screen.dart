import 'package:flutter/material.dart';
import 'pantry_screen.dart';
import 'shopping_list_screen.dart';
import 'recipes_screen.dart';
import '../widgets/app_bottom_nav.dart';

class MainScreen extends StatefulWidget {
  final String houseName;
  const MainScreen({super.key, required this.houseName});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Impostiamo 1 di default in modo che la "Dispensa" (centrale) sia la prima ad aprirsi
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    // Ordine aggiornato: Spesa (0), Dispensa (1), Ricette (2)
    final List<Widget> screens = [
      const ShoppingListScreen(),
      PantryScreen(houseName: widget.houseName),
      const RecipesScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          AppBottomNavItem(icon: Icons.shopping_cart_outlined, label: 'Spesa'),
          AppBottomNavItem(icon: Icons.kitchen, label: 'Dispensa'),
          AppBottomNavItem(icon: Icons.restaurant_menu, label: 'Ricette'),
        ],
      ),
    );
  }
}