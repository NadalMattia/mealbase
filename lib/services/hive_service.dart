import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';

class HiveService {
  String _boxName = 'products';

  // Metodo STATICO: chiamato da main.dart senza inizializzare la classe
  static void registerAdapter() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProductAdapter());
    }
  }

  // Metodo di ISTANZA: chiamato da PantryProvider per cambiare database
  Future<void> switchHouse(String houseName) async {
    _boxName = 'products_$houseName';
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Product>(_boxName);
    }
  }

  Box<Product> get _box => Hive.box<Product>(_boxName);

  List<Product> getAllProducts() => Hive.isBoxOpen(_boxName) ? _box.values.toList() : [];

  Future<void> addProduct(Product product) async => await _box.put(product.id, product);

  Future<void> updateProduct(Product product) async => await product.save();

  Future<void> deleteProduct(String id) async => await _box.delete(id);
}