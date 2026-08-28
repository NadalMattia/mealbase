import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pantry_provider.dart';
import '../models/product.dart';
import 'product_form_screen.dart';

class PantryScreen extends StatelessWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final products = provider.byPosizione('Tutto');

    return Scaffold(
      appBar: AppBar(title: const Text('Dispensa')),
      body: products.isEmpty
          ? const Center(child: Text('Nessun prodotto in dispensa'))
          : ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final Product p = products[index];
          return ListTile(
            title: Text(p.nome),
            subtitle: Text(
              '${p.quantita} ${p.unita} · ${p.categoria} · ${p.posizione}',
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
        },
      ),
    );
  }
}