import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import 'house_scoped_hive_service.dart';

class HiveService extends HouseScopedHiveService<Product> {
  HiveService() : super('products');

  // Metodo STATICO: chiamato da main.dart senza inizializzare la classe.
  static void registerAdapter() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProductAdapter());
    }
  }

  List<Product> getAllProducts() => getAll();

  Future<void> addProduct(Product product) async => await put(product.id, product);

  Future<void> updateProduct(Product product) async => await product.save();

  Future<void> deleteProduct(String id) async => await delete(id);
}
