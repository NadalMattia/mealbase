import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_provider.dart';
import '../models/shopping_item.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _controller = TextEditingController();

  void _addItem() {
    context.read<ShoppingListProvider>().addItem(_controller.text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingListProvider>();
    final daAcquistare = provider.daAcquistare;
    final giaPreso = provider.giaPreso;

    return Scaffold(
      appBar: AppBar(title: const Text('Lista della spesa')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Aggiungi prodotto',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addItem,
                  child: const Text('Aggiungi'),
                ),
              ],
            ),
          ),
          _SectionHeader(title: 'Spesa', color: Colors.orange.shade100),
          Expanded(
            child: _ItemList(
              items: daAcquistare,
              emptyText: 'Nessun prodotto da acquistare',
              onTapItem: (item) => provider.toggleItem(item),
              onDeleteItem: (item) => provider.deleteItem(item.id),
            ),
          ),
          const Divider(height: 1, thickness: 2),
          _SectionHeader(title: 'Già preso', color: Colors.green.shade100),
          Expanded(
            child: _ItemList(
              items: giaPreso,
              emptyText: 'Nessun prodotto ancora preso',
              onTapItem: (item) => provider.toggleItem(item),
              onDeleteItem: (item) => provider.deleteItem(item.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _ItemList extends StatelessWidget {
  final List<ShoppingItem> items;
  final String emptyText;
  final void Function(ShoppingItem) onTapItem;
  final void Function(ShoppingItem) onDeleteItem;

  const _ItemList({
    required this.items,
    required this.emptyText,
    required this.onTapItem,
    required this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text(emptyText));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: Icon(
            item.inCarrello ? Icons.check_circle : Icons.radio_button_unchecked,
          ),
          title: Text(item.nome),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => onDeleteItem(item),
          ),
          onTap: () => onTapItem(item),
        );
      },
    );
  }
}