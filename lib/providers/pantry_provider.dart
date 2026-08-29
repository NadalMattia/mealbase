import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/hive_service.dart';

class PantryProvider extends ChangeNotifier {
  final HiveService _hiveService = HiveService();
  List<Product> _products = [];

  List<Product> get products => _products;

  PantryProvider() {
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