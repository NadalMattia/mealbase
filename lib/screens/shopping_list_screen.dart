import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_provider.dart';
import '../models/shopping_item.dart';
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text('$count elementi eliminati'),
          ],
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
        duration: const Duration(seconds: 2),
      ),
    );
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
      backgroundColor: Colors.white,
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
              child: _DeleteSelectionBar(
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
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            InkWell(
              onTap: _toggleSelectionMode,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: _isSelectionMode ? Colors.black : Colors.grey.shade400,
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
          child: Text('Nessun prodotto', style: TextStyle(color: Colors.grey.shade400)),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('${item.nome} eliminato'),
                      ],
                    ),
                    backgroundColor: Colors.black87,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}

class _DeleteSelectionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const _DeleteSelectionBar({
    required this.selectedCount,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(32),
      color: Colors.black,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onCancel,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(32)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.close, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'ANNULLA',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0),
                    ),
                  ],
                ),
              ),
            ),
            Container(width: 1, height: 28, color: Colors.white38),
            Expanded(
              child: InkWell(
                onTap: onDelete,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(32)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.delete, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'ELIMINA ($selectedCount)',
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}