import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../models/location.dart';
import '../theme/app_theme.dart';

class ManageLocationsScreen extends StatefulWidget {
  const ManageLocationsScreen({super.key});

  @override
  State<ManageLocationsScreen> createState() => _ManageLocationsScreenState();
}

class _ManageLocationsScreenState extends State<ManageLocationsScreen> {
  final _newLocationController = TextEditingController();

  @override
  void dispose() {
    _newLocationController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuovo spazio'),
        content: TextField(
          controller: _newLocationController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Es. Spezie, Bevande...'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _newLocationController.clear();
              Navigator.pop(context);
            },
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              context.read<LocationProvider>().addLocation(_newLocationController.text);
              _newLocationController.clear();
              Navigator.pop(context);
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocationProvider>();
    final locations = provider.locations;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Gestisci spazi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Tieni premuto sulle tre barre orizzontali per riordinare gli spazi. '
                  'Puoi eliminare uno spazio con il cestino.',
              style: TextStyle(color: AppColors.grey600),
            ),
          ),
          Expanded(
            child: locations.isEmpty
                ? Center(child: Text('Nessuno spazio ancora creato', style: AppTextStyles.emptyState))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: locations.length,
                    onReorder: (oldIndex, newIndex) {
                      context.read<LocationProvider>().reorder(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final Location loc = locations[index];
                      return _LocationTile(
                        key: ValueKey(loc.id),
                        index: index,
                        location: loc,
                        onDelete: () => context.read<LocationProvider>().deleteLocation(loc.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('AGGIUNGI SPAZIO', style: AppTextStyles.pillButtonLabel),
        backgroundColor: AppColors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        onPressed: _showAddDialog,
      ),
    );
  }
}

/// Tile di uno spazio, restilizzata secondo il design system minimale
/// dell'app (bordo sottile, angoli arrotondati coerenti) al posto della
/// `Card` + `ListTile` Material di default usate in precedenza, che
/// stonavano rispetto al resto delle schermate.
class _LocationTile extends StatelessWidget {
  final int index;
  final Location location;
  final VoidCallback onDelete;

  const _LocationTile({
    super.key,
    required this.index,
    required this.location,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.grey200),
      ),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: index,
          child: Icon(Icons.drag_handle, color: AppColors.grey400),
        ),
        title: Text(location.nome, style: AppTextStyles.cardTitle.copyWith(fontSize: 14)),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: AppColors.grey500),
          onPressed: onDelete,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
    );
  }
}
