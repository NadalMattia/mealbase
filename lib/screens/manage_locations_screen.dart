import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../providers/pantry_provider.dart';
import '../models/location.dart';
import '../theme/app_theme.dart';

/// Gestione degli spazi della dispensa: creazione, riordino manuale ed
/// eliminazione con riassegnazione dei prodotti contenuti.
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

  /// Chiede il nome di un nuovo spazio.
  ///
  /// Lo StatefulBuilder permette al dialog di mostrare il messaggio di
  /// nome duplicato aggiornando solo se stesso.
  void _showAddDialog() {
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Nuovo spazio'),
          content: TextField(
            controller: _newLocationController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Es. Spezie, Bevande...',
              errorText: errorText,
            ),
            onChanged: (_) {
              if (errorText != null) setDialogState(() => errorText = null);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _newLocationController.clear();
                Navigator.pop(dialogContext);
              },
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () async {
                final added =
                    await context.read<LocationProvider>().addLocation(_newLocationController.text);
                if (!dialogContext.mounted) return;
                if (added) {
                  _newLocationController.clear();
                  Navigator.pop(dialogContext);
                } else {
                  setDialogState(() => errorText = 'Esiste già uno spazio con questo nome');
                }
              },
              child: const Text('Aggiungi'),
            ),
          ],
        ),
      ),
    );
  }

  /// Chiede conferma prima di eliminare uno spazio.
  ///
  /// Se lo spazio contiene prodotti, il dialog ne indica il numero e fa
  /// scegliere la destinazione: [Product.posizione] referenzia lo spazio
  /// per nome, quindi senza riassegnazione i prodotti resterebbero
  /// visibili solo nella tab "Tutto".
  Future<void> _confirmDelete(BuildContext context, Location location) async {
    final pantryProvider = context.read<PantryProvider>();
    final locationProvider = context.read<LocationProvider>();

    final affectedCount =
        pantryProvider.products.where((p) => p.posizione == location.nome).length;
    final otherLocations =
        locationProvider.locations.where((l) => l.id != location.id).toList();

    String? targetName = otherLocations.isNotEmpty ? otherLocations.first.nome : null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Eliminare "${location.nome}"?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (affectedCount == 0)
                const Text('Questo spazio non contiene prodotti.')
              else ...[
                Text(
                  affectedCount == 1
                      ? '1 prodotto è allocato qui.'
                      : '$affectedCount prodotti sono allocati qui.',
                ),
                const SizedBox(height: 12),
                if (otherLocations.isNotEmpty) ...[
                  const Text('Verranno spostati in:'),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    value: targetName,
                    isExpanded: true,
                    items: otherLocations
                        .map((l) => DropdownMenuItem(value: l.nome, child: Text(l.nome)))
                        .toList(),
                    onChanged: (val) => setDialogState(() => targetName = val),
                  ),
                ] else
                  const Text(
                    'Non ci sono altri spazi: resteranno visibili solo nella tab "Tutto".',
                  ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ANNULLA'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('ELIMINA', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    if (affectedCount > 0 && targetName != null) {
      await pantryProvider.reassignPosizione(location.nome, targetName!);
    }
    await locationProvider.deleteLocation(location.id);
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
                        onDelete: () => _confirmDelete(context, loc),
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

/// Riga di un singolo spazio, con maniglia di trascinamento a sinistra e
/// azione di eliminazione a destra.
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
