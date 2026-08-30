import 'package:flutter/material.dart';
import '../widgets/coming_soon_screen.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      appBarTitle: 'Ricette',
      icon: Icons.restaurant_menu,
      title: 'Funzionalità in arrivo',
      message: 'Il suggerimento ricette basato sugli ingredienti in dispensa '
          'sarà disponibile in una prossima versione.',
    );
  }
}
