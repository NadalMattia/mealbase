import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';

class HiveService {
  static const String boxName = 'products';

  static Future<void> init() async {
    Hive.registerAdapter(ProductAdapter());
    await Hive.openBox<Product>(boxName);
  }

  Box<Product> get _box => Hive.box<Product>(boxName);

  List<Product> getAllProducts() => _box.values.toList();

  Future<void> addProduct(Product product) async {
    await _box.put(product.id, product);
  }

  Future<void> updateProduct(Product product) async {
    await product.save();
  }

  Future<void> deleteProduct(String id) async {
    await _box.delete(id);
  }
}