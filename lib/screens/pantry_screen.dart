import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pantry_provider.dart';
import '../providers/location_provider.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../widgets/pill_action_bar.dart';
import 'scanner_screen.dart';
import 'product_form_screen.dart';
import 'manage_locations_screen.dart';
import 'house_settings_screen.dart';
import '../widgets/product_card.dart';

class PantryScreen extends StatefulWidget {
  final String houseName;
  const PantryScreen({super.key, required this.houseName});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  List<String> _currentTabs = [];
  String _searchQuery = '';

  // Stati per la selezione multipla
  bool _isSelectionMode = false;
  final Set<String> _selectedProducts = {};

  void _rebuildTabController(List<String> tabs) {
    if (_tabController != null && _listEquals(_currentTabs, tabs)) return;
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

  // Abilita/Disabilita la modalità selezione
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedProducts.clear();
    });
  }

  // Aggiunge o rimuove un prodotto dalla selezione
  void _toggleProductSelection(String id) {
    setState(() {
      if (_selectedProducts.contains(id)) {
        _selectedProducts.remove(id);
      } else {
        _selectedProducts.add(id);
      }
    });
  }

  void _deleteSelected() {
    if (_selectedProducts.isEmpty) return;

    final count = _selectedProducts.length;
    final provider = context.read<PantryProvider>();

    for (final id in _selectedProducts) {
      provider.deleteProduct(id);
    }

    _toggleSelectionMode();
    AppSnackbar.showDeleted(context, message: '$count prodotti eliminati');
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final tabs = ['Tutto', ...locationProvider.locations.map((l) => l.nome)];
    _rebuildTabController(tabs);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          widget.houseName.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.people_outline, color: AppColors.grey400),
            onPressed: () => AppSnackbar.showComingSoon(context, 'Condivisione coinquilini'),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.grey400),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HouseSettingsScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        color: AppColors.black,
                      ),
                      labelColor: AppColors.white,
                      unselectedLabelColor: AppColors.grey400,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      tabs: tabs.map((t) => Tab(
                        height: 32,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(t.toUpperCase()),
                        ),
                      )).toList(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: AppColors.grey300),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManageLocationsScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: TextField(
                          onChanged: (value) => setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Cerca ingredienti',
                            hintStyle: AppTextStyles.hint,
                            prefixIcon: Icon(Icons.search, color: AppColors.grey400),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tasto cestino: attiva/disattiva la modalità selezione
                    _SquareButton(
                      icon: Icons.delete_outline,
                      isActive: _isSelectionMode,
                      onTap: _toggleSelectionMode,
                    ),
                    const SizedBox(width: 8),
                    _SquareButton(
                      icon: Icons.tune,
                      isActive: false,
                      onTap: () => AppSnackbar.showComingSoon(context, 'Filtri avanzati'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: tabs.map((posizione) => _ProductList(
              posizione: posizione,
              searchQuery: _searchQuery,
              isSelectionMode: _isSelectionMode,
              selectedProducts: _selectedProducts,
              onToggleSelection: _toggleProductSelection,
            )).toList(),
          ),

          // Switch tra la barra standard e la barra di eliminazione
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: _isSelectionMode
                ? DeleteSelectionBar(
                    selectedCount: _selectedProducts.length,
                    onDelete: _deleteSelected,
                    onCancel: _toggleSelectionMode,
                  )
                : PillActionBar(
                    actions: [
                      PillBarAction(
                        icon: Icons.edit,
                        label: 'INSERISCI',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProductFormScreen()),
                        ),
                      ),
                      PillBarAction(
                        icon: Icons.crop_free,
                        label: 'SCANSIONA',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ScannerScreen()),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _SquareButton({required this.icon, required this.onTap, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: isActive ? AppColors.black : AppColors.grey50,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: isActive ? AppColors.white : AppColors.grey400, size: 20),
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final String posizione;
  final String searchQuery;
  final bool isSelectionMode;
  final Set<String> selectedProducts;
  final Function(String) onToggleSelection;

  const _ProductList({
    required this.posizione,
    required this.searchQuery,
    required this.isSelectionMode,
    required this.selectedProducts,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    var products = provider.byPosizione(posizione);

    if (searchQuery.trim().isNotEmpty) {
      products = products.where(
              (p) => p.nome.toLowerCase().contains(searchQuery.toLowerCase().trim())
      ).toList();
    }

    if (products.isEmpty) {
      return Center(
          child: Text(
            searchQuery.isEmpty ? 'Nessun prodotto qui' : 'Nessun risultato',
            style: AppTextStyles.emptyState,
          )
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final Product p = products[index];

        return ProductCard(
          name: p.nome,
          imageUrl: p.imagePath,
          isSelectable: isSelectionMode,
          isSelected: selectedProducts.contains(p.id),
          onTap: () {
            if (isSelectionMode) {
              onToggleSelection(p.id);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => ProductFormScreen(existingProduct: p),
                ),
              );
            }
          },
          onDelete: () {
            context.read<PantryProvider>().deleteProduct(p.id);
            AppSnackbar.showDeleted(context, message: '${p.nome} eliminato');
          },
        );
      },
    );
  }
}
