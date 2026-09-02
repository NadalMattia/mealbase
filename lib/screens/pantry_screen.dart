import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pantry_sort_option.dart';
import '../providers/pantry_provider.dart';
import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../widgets/pill_action_bar.dart';
import '../widgets/pantry_filter_bottom_sheet.dart';
import '../widgets/pantry_product_list.dart';
import 'scanner_screen.dart';
import 'product_form_screen.dart';
import 'manage_locations_screen.dart';
import 'house_settings_screen.dart';
import '../services/onboarding_service.dart';
import '../widgets/scan_tip_bubble.dart';

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
  final TextEditingController _searchController = TextEditingController();

  PantrySortOption _selectedSort = PantrySortOption.insertionDesc;
  String? _selectedCategory;

  bool _isSelectionMode = false;
  final Set<String> _selectedProducts = {};

  bool _showScanTip = !OnboardingService.hasSeenScanTip;

  void _dismissScanTip() {
    setState(() => _showScanTip = false);
    OnboardingService.markScanTipSeen();
  }

  void _rebuildTabController(List<String> tabs) {
    if (_tabController != null && _listEquals(_currentTabs, tabs)) return;
    _currentTabs = tabs;
    _tabController?.dispose();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController!.addListener(() {
      if (mounted) setState(() {});
    });
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
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedProducts.clear();
    });
  }

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

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PantryFilterBottomSheet(
        currentSort: _selectedSort,
        currentCategory: _selectedCategory,
        onApply: (sort, category) {
          setState(() {
            _selectedSort = sort;
            _selectedCategory = category;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final tabs = ['Tutto', ...locationProvider.locations.map((l) => l.nome)];
    _rebuildTabController(tabs);

    final isFilterActive = _selectedCategory != null || _selectedSort != PantrySortOption.insertionDesc;

    final pantryIsEmpty = context.watch<PantryProvider>().products.isEmpty;

    return GestureDetector(
      onTap: () => AppSnackbar.hide(context),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.pannaWarm,
        appBar: AppBar(
          backgroundColor: AppColors.pannaWarm,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 16,
          title: Text(
            widget.houseName.toUpperCase(),
            style: AppTextStyles.screenTitle,
          ),
          actions: [
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HouseSettingsScreen()),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.people_outline, color: AppColors.verdeBosco),
                    SizedBox(width: 12),
                    Icon(Icons.settings_outlined, color: AppColors.verdeBosco),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(112),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          dividerColor: Colors.transparent,
                          // FIX: prima il TabBar disegnava un proprio
                          // "indicator" (il box grigio di selezione),
                          // dimensionato su tutta l'area del Tab
                          // (`indicatorSize.tab`, che include anche
                          // `labelPadding`). Il `Container` interno di
                          // ogni Tab, invece, aveva la sua decorazione
                          // separata (con padding orizzontale 16) e
                          // diventava trasparente da selezionato per
                          // "lasciar vedere" l'indicator sotto. I due box
                          // avevano dimensioni leggermente diverse (il
                          // `labelPadding: only(right: 8)` allargava
                          // l'indicator 8px in più a destra rispetto al
                          // Container interno), quindi il testo appariva
                          // spostato a sinistra rispetto al pill grigio
                          // quando il tab era selezionato.
                          //
                          // Ora l'indicator è completamente trasparente:
                          // è sempre e solo il Container interno di ogni
                          // Tab (identico nei due stati, cambia solo il
                          // colore) a disegnare lo sfondo, quindi il testo
                          // resta sempre centrato nello stesso identico box.
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: const BoxDecoration(),
                          labelColor: AppColors.verdeBosco,
                          unselectedLabelColor: AppColors.grey600,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.6),
                          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.only(right: 8),
                          tabs: List.generate(tabs.length, (index) {
                            final isSelected = _tabController?.index == index;
                            return Tab(
                              height: 38,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                  color: isSelected ? AppColors.grey300 : AppColors.grey100.withValues(alpha: 0.6),
                                ),
                                child: Text(tabs[index].toUpperCase()),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ManageLocationsScreen()),
                          );
                        },
                        child: Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.grey300, width: 0.8),
                          ),
                          child: const Icon(Icons.add, color: AppColors.verdeBosco, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
                            border: Border.all(color: AppColors.grey200, width: 1),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() => _searchQuery = value),
                            decoration: InputDecoration(
                              hintText: 'Cerca ingredienti...',
                              hintStyle: AppTextStyles.hint,
                              prefixIcon: const Icon(Icons.search, color: AppColors.grey400, size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.cancel, color: AppColors.grey400, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SquareButton(
                        icon: Icons.delete_outline,
                        isActive: _isSelectionMode,
                        onTap: _toggleSelectionMode,
                      ),
                      const SizedBox(width: 8),
                      _SquareButton(
                        icon: Icons.tune,
                        isActive: isFilterActive,
                        onTap: _openFilterBottomSheet,
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
              children: tabs.map((posizione) => PantryProductList(
                posizione: posizione,
                searchQuery: _searchQuery,
                selectedCategory: _selectedCategory,
                selectedSort: _selectedSort,
                isSelectionMode: _isSelectionMode,
                selectedProducts: _selectedProducts,
                onToggleSelection: _toggleProductSelection,
              )).toList(),
            ),
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
            if (_showScanTip && !_isSelectionMode && !pantryIsEmpty)
              Positioned(
                right: 16,
                bottom: 84, // 20 (margine barra) + 56 (altezza barra) + 8 (respiro)
                child: ScanTipBubble(onDismiss: _dismissScanTip),
              ),
          ],
        ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: isActive ? AppColors.verdeBosco : AppColors.grey50,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isActive ? AppColors.verdeBosco : AppColors.grey200,
            width: 1,
          ),
        ),
        child: Icon(icon, color: isActive ? AppColors.white : AppColors.grey400, size: 20),
      ),
    );
  }
}