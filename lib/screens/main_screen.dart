import 'package:flutter/material.dart';
import 'pantry_screen.dart';
import 'shopping_list_screen.dart';
import 'recipes_screen.dart';

class MainScreen extends StatefulWidget {
  final String houseName;
  const MainScreen({super.key, required this.houseName});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // La lista viene generata nel build per poter accedere a widget.houseName[cite: 5]
    final List<Widget> screens = [
      PantryScreen(houseName: widget.houseName), // Passiamo il nome qui
      const ShoppingListScreen(),
      const RecipesScreen(),
    ];

    return Scaffold(
      // L'AppBar è stata rimossa completamente da qui
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Spesa'),
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Dispensa'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Ricette'),
        ],
      ),
    );
  }
}