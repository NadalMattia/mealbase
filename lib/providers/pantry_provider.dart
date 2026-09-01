import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/hive_service.dart';

class PantryProvider extends ChangeNotifier {
  final HiveService _hiveService = HiveService();
  List<Product> _products = [];

  List<Product> get products => _products;

  PantryProvider();

  Future<void> switchHouse(String houseName) async {
    await _hiveService.switchHouse(houseName);
    loadProducts();
  }

  void loadProducts() {
    _products = _hiveService.getAllProducts();
    notifyListeners();
  }

  List<Product> byPosizione(String posizione) {
    if (posizione == 'Tutto') return _products;
    return _products.where((p) => p.posizione == posizione).toList();
  }

  /// Cerca tra i prodotti esistenti e ne restituisce la lista unica
  List<Product> searchProducts(String query) {
    if (query.trim().isEmpty) return [];

    final Map<String, Product> uniqueMatches = {};
    for (var p in _products) {
      if (p.nome.toLowerCase().contains(query.toLowerCase())) {
        // Se troviamo doppioni, salviamo la versione che possiede un'immagine
        if (!uniqueMatches.containsKey(p.nome) || (p.imagePath != null && p.imagePath!.isNotEmpty)) {
          uniqueMatches[p.nome] = p;
        }
      }
    }
    return uniqueMatches.values.toList();
  }

  /// Recupera un prodotto per nome per estrarre immagine e categoria
  Product? findByName(String name) {
    try {
      return _products.firstWhere(
            (p) => p.nome.toLowerCase() == name.trim().toLowerCase() && p.imagePath != null && p.imagePath!.isNotEmpty,
      );
    } catch (_) {
      try {
        return _products.firstWhere((p) => p.nome.toLowerCase() == name.trim().toLowerCase());
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> addProduct(Product product) async {
    await _hiveService.addProduct(product);
    loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    await _hiveService.updateProduct(product);
    loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    await _hiveService.deleteProduct(id);
    loadProducts();
  }
}