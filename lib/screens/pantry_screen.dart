import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pantry_provider.dart';
import '../providers/location_provider.dart';
import '../models/product.dart';
import 'scanner_screen.dart';
import 'product_form_screen.dart';
import 'manage_locations_screen.dart';
import 'house_settings_screen.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

// NOTA: TickerProviderStateMixin (non "Single") perché il TabController
// viene ricreato ogni volta che cambia il numero di spazi/posizioni.
class _PantryScreenState extends State<PantryScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  List<String> _currentTabs = [];

  void _rebuildTabController(List<String> tabs) {
    if (_tabController != null && _listEquals(_currentTabs, tabs)) {
      return;
    }
    _currentTabs = tabs;
    _tabController?.dispose();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final tabs = ['Tutto', ...locationProvider.locations.map((l) => l.nome)];
    _rebuildTabController(tabs);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispensa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Impostazioni Casa 1',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HouseSettingsScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: tabs.map((t) => Tab(text: t)).toList(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Gestisci spazi',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageLocationsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children:
            tabs.map((posizione) => _ProductList(posizione: posizione)).toList(),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: _ScanInsertBar(
              onInsert: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductFormScreen()),
              ),
              onScan: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScannerScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra pillola fluttuante con azioni "Inserisci" e "Scansiona",
/// posizionata sopra la lista prodotti (vedi mockup fornito).
class _ScanInsertBar extends StatelessWidget {
  final VoidCallback onInsert;
  final VoidCallback onScan;

  const _ScanInsertBar({required this.onInsert, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(32),
      color: Theme.of(context).colorScheme.primary,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            Expanded(
              child: _BarButton(
                icon: Icons.edit,
                label: 'Inserisci',
                onTap: onInsert,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(32),
                ),
              ),
            ),
            Container(width: 1, height: 28, color: Colors.white38),
            Expanded(
              child: _BarButton(
                icon: Icons.crop_free,
                label: 'Scansiona',
                onTap: onScan,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  const _BarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final String posizione;
  const _ProductList({required this.posizione});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final products = provider.byPosizione(posizione);

    if (products.isEmpty) {
      return const Center(child: Text('Nessun prodotto qui'));
    }

    return ListView.builder(
      // padding maggiorato in basso per non finire sotto la barra pillola
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final Product p = products[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.fastfood)),
            title: Text(p.nome),
            subtitle: Text(
              '${p.quantita} ${p.unita} · ${p.categoria}'
                  '${p.dataScadenza != null ? " · Scad. ${p.dataScadenza!.day}/${p.dataScadenza!.month}/${p.dataScadenza!.year}" : ""}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                context.read<PantryProvider>().deleteProduct(p.id);
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductFormScreen(existingProduct: p),
                ),
              );
            },
          ),
        );
      },
    );
  }
}