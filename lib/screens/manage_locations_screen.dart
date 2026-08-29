import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../models/location.dart';

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
      appBar: AppBar(title: const Text('Gestisci spazi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Tieni premuto sulle tre barre orizzontali per riordinare gli spazi. '
                  'Puoi eliminare uno spazio con il cestino.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: locations.length,
              onReorder: (oldIndex, newIndex) {
                context.read<LocationProvider>().reorder(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final Location loc = locations[index];
                return Card(
                  key: ValueKey(loc.id),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                    title: Text(loc.nome),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        context.read<LocationProvider>().deleteLocation(loc.id);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi spazio'),
        onPressed: _showAddDialog,
      ),
    );
  }
}