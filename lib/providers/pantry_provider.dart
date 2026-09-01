import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

class PantryProvider extends ChangeNotifier {
  final HiveService _hiveService = HiveService();
  List<Product> _products = [];
  final Set<String> _pendingDeleteIds = {};

  PantryProvider();

  List<Product> get products =>
      _products.where((p) => !_pendingDeleteIds.contains(p.id)).toList();

  Future<void> switchHouse(String houseName) async {
    await _hiveService.switchHouse(houseName);
    loadProducts();
  }

  void loadProducts() {
    _products = _hiveService.getAllProducts();
    notifyListeners();
  }

  List<Product> byPosizione(String posizione) {
    final activeProducts = products;
    if (posizione == 'Tutto') return activeProducts;
    return activeProducts.where((p) => p.posizione == posizione).toList();
  }

  List<Product> searchProducts(String query) {
    if (query.trim().isEmpty) return [];

    final Map<String, Product> uniqueMatches = {};
    for (var p in products) {
      if (p.nome.toLowerCase().contains(query.toLowerCase())) {
        if (!uniqueMatches.containsKey(p.nome) || (p.imagePath != null && p.imagePath!.isNotEmpty)) {
          uniqueMatches[p.nome] = p;
        }
      }
    }
    return uniqueMatches.values.toList();
  }

  Product? findByName(String name) {
    try {
      return products.firstWhere(
            (p) => p.nome.toLowerCase() == name.trim().toLowerCase() && p.imagePath != null && p.imagePath!.isNotEmpty,
      );
    } catch (_) {
      try {
        return products.firstWhere((p) => p.nome.toLowerCase() == name.trim().toLowerCase());
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> addProduct(Product product) async {
    await _hiveService.addProduct(product);
    if (product.dataScadenza != null) {
      await NotificationService().scheduleExpirationNotification(
        id: product.id,
        productName: product.nome,
        expirationDate: product.dataScadenza!,
      );
    }
    loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    if (product.isInBox) {
      await product.save();
    } else {
      await _hiveService.addProduct(product);
    }

    if (product.dataScadenza != null) {
      await NotificationService().scheduleExpirationNotification(
        id: product.id,
        productName: product.nome,
        expirationDate: product.dataScadenza!,
      );
    } else {
      await NotificationService().cancelNotification(product.id);
    }
    loadProducts();
  }

  void hideProduct(String id) {
    _pendingDeleteIds.add(id);
    notifyListeners();
  }

  void cancelDeleteProduct(String id) {
    _pendingDeleteIds.remove(id);
    notifyListeners();
  }

  Future<void> confirmDeleteProduct(String id) async {
    _pendingDeleteIds.remove(id);
    await NotificationService().cancelNotification(id);
    await _hiveService.deleteProduct(id);
    loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    await NotificationService().cancelNotification(id);
    await _hiveService.deleteProduct(id);
    loadProducts();
  }
}