import 'package:flutter/material.dart';
import '../widgets/coming_soon_screen.dart';

/// Impostazioni della casa. Non ancora sviluppata.
class HouseSettingsScreen extends StatelessWidget {
  const HouseSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      appBarTitle: 'Impostazioni Casa',
      icon: Icons.settings,
      title: 'Funzionalità in arrivo',
      message: 'Gestione account condivisi e link di invito '
          'saranno disponibili in una prossima versione.',
    );
  }
}
