import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_provider.dart';
import '../models/shopping_item.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../widgets/pill_action_bar.dart';
import '../widgets/product_card.dart';
import 'shopping_item_edit_screen.dart';
import 'shopping_scanner_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedItems.clear();
    });
  }

  void _toggleItemSelection(String id) {
    setState(() {
      if (_selectedItems.contains(id)) {
        _selectedItems.remove(id);
      } else {
        _selectedItems.add(id);
      }
    });
  }

  void _deleteSelected() {
    if (_selectedItems.isEmpty) return;

    final count = _selectedItems.length;
    final provider = context.read<ShoppingListProvider>();

    for (final id in _selectedItems) {
      provider.deleteItem(id);
    }

    _toggleSelectionMode();
    AppSnackbar.showDeleted(context, message: '$count elementi eliminati');
  }

  void _showAddItemDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Aggiungi alla spesa'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nome prodotto'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<ShoppingListProvider>().addItem(controller.text.trim());
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingListProvider>();
    final daAcquistare = provider.daAcquistare;
    final giaPreso = provider.giaPreso;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                _buildSectionHeader('LISTA DELLA SPESA'),
                _buildGrid(daAcquistare, provider),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                _buildSectionHeader('NEL CARRELLO'),
                _buildGrid(giaPreso, provider),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),

          if (_isSelectionMode)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: DeleteSelectionBar(
                selectedCount: _selectedItems.length,
                onDelete: _deleteSelected,
                onCancel: _toggleSelectionMode,
              ),
            ),
        ],
      ),
      floatingActionButton: !_isSelectionMode
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true, // Apre con animazione dal basso
              builder: (_) => const ShoppingScannerScreen(),
            ),
          );
        },
        child: const Icon(Icons.add, size: 28),
      )
          : null,
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.sectionLabel),
            InkWell(
              onTap: _toggleSelectionMode,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: _isSelectionMode ? AppColors.black : AppColors.grey400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<ShoppingItem> items, ShoppingListProvider provider) {
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text('Nessun prodotto', style: AppTextStyles.emptyState),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final item = items[index];
            return ProductCard(
              name: item.nome,
              isSelectable: _isSelectionMode,
              isSelected: _selectedItems.contains(item.id),
              onTap: () {
                if (_isSelectionMode) {
                  _toggleItemSelection(item.id);
                } else {
                  // Con un tocco si sposta tra Carrello e Spesa
                  provider.toggleItem(item);
                }
              },
              onLongPress: () {
                if (!_isSelectionMode) {
                  // Tenendo premuto si apre il form per modificare
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => ShoppingItemEditScreen(item: item),
                    ),
                  );
                }
              },
              onDelete: () {
                provider.deleteItem(item.id);
                AppSnackbar.showDeleted(context, message: '${item.nome} eliminato');
              },
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}
