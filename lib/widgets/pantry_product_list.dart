import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pantry_sort_option.dart';
import '../models/product.dart';
import '../providers/pantry_provider.dart';
import '../screens/product_form_screen.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import 'product_card.dart';
import 'pantry_empty_state.dart';

class PantryProductList extends StatelessWidget {
  final String posizione;
  final String searchQuery;
  final String? selectedCategory;
  final PantrySortOption selectedSort;
  final bool isSelectionMode;
  final Set<String> selectedProducts;
  final Function(String) onToggleSelection;

  const PantryProductList({
    super.key,
    required this.posizione,
    required this.searchQuery,
    required this.selectedCategory,
    required this.selectedSort,
    required this.isSelectionMode,
    required this.selectedProducts,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    var products = provider.byPosizione(posizione);

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      products = products.where((p) {
        final matchNome = p.nome.toLowerCase().contains(q);
        final matchMarca = p.marca != null && p.marca!.toLowerCase().contains(q);
        return matchNome || matchMarca;
      }).toList();
    }

    if (selectedCategory != null && selectedCategory != 'Tutte') {
      products = products.where((p) => p.categoria.toLowerCase() == selectedCategory!.toLowerCase()).toList();
    }

    products.sort((a, b) {
      switch (selectedSort) {
        case PantrySortOption.expirationAsc:
          if (a.dataScadenza == null && b.dataScadenza == null) return 0;
          if (a.dataScadenza == null) return 1;
          if (b.dataScadenza == null) return -1;
          return a.dataScadenza!.compareTo(b.dataScadenza!);

        case PantrySortOption.insertionDesc:
          return b.dataAcquisto.compareTo(a.dataAcquisto);

        case PantrySortOption.insertionAsc:
          return a.dataAcquisto.compareTo(b.dataAcquisto);

        case PantrySortOption.category:
          final catComp = a.categoria.toLowerCase().compareTo(b.categoria.toLowerCase());
          if (catComp != 0) return catComp;
          return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
      }
    });

    if (products.isEmpty) {
      final isTrulyEmpty = provider.products.isEmpty &&
          searchQuery.trim().isEmpty &&
          (selectedCategory == null || selectedCategory == 'Tutte');

      if (isTrulyEmpty) {
        return const PantryEmptyState();
      }

      return Center(
        child: Text(
          searchQuery.isEmpty && selectedCategory == null ? 'Nessun prodotto qui' : 'Nessun risultato trovato',
          style: AppTextStyles.emptyState,
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 96),
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
          brand: p.marca,
          imageUrl: p.imagePath,
          expirationDate: p.dataScadenza,
          quantity: p.quantita,
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
          onDelete: () async {
            final pantryProvider = context.read<PantryProvider>();
            final productId = p.id;

            pantryProvider.hideProduct(productId);

            final snackbarController = AppSnackbar.showDeleted(
              context,
              message: '${p.nome} eliminato',
              onUndo: () => pantryProvider.cancelDeleteProduct(productId),
            );

            final reason = await snackbarController.closed;
            if (reason != SnackBarClosedReason.action) {
              await pantryProvider.confirmDeleteProduct(productId);
            }
          },
        );
      },
    );
  }
}