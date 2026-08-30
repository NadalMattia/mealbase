import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:provider/provider.dart';
import 'main_screen.dart';
import '../providers/pantry_provider.dart';
import '../providers/location_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/house_provider.dart';
import '../theme/app_theme.dart';

class HouseListScreen extends StatefulWidget {
  const HouseListScreen({super.key});

  @override
  State<HouseListScreen> createState() => _HouseListScreenState();
}

class _HouseListScreenState extends State<HouseListScreen> {
  Future<void> _showAddHouseDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nuova casa'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nome casa'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                // Persistita su Hive tramite HouseProvider, non più solo in
                // memoria: sopravvive al riavvio dell'app.
                context.read<HouseProvider>().addHouse(controller.text.trim());
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final houses = context.watch<HouseProvider>().houses;

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        backgroundColor: AppColors.grey50,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('MealBase', style: AppTextStyles.screenTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          const Text(
            'LE TUE CASE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text('Seleziona o aggiungi una casa', style: AppTextStyles.subtitle),
          const SizedBox(height: 20),
          ...houses.map(
            (house) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _HouseCard(
                name: house.nome,
                onTap: () async {
                  // 1. Inizializza i database per la casa specifica
                  await context.read<PantryProvider>().switchHouse(house.nome);
                  await context.read<LocationProvider>().switchHouse(house.nome);
                  await context.read<ShoppingListProvider>().switchHouse(house.nome);

                  // 2. Naviga alla schermata principale della casa
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MainScreen(houseName: house.nome),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          DottedBorder(
            color: AppColors.grey400,
            strokeWidth: 1.2,
            dashPattern: const [6, 4],
            borderType: BorderType.RRect,
            radius: const Radius.circular(AppRadius.lg),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: _showAddHouseDialog,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  alignment: Alignment.center,
                  child: Text(
                    'AGGIUNGI UNA NUOVA CASA',
                    style: TextStyle(
                      color: AppColors.grey500,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HouseCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _HouseCard({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.home, color: AppColors.grey400),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }
}
