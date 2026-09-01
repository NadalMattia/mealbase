import 'package:hive_flutter/hive_flutter.dart';
import '../models/house.dart';
import '../models/product.dart';
import 'house_scoped_hive_service.dart';

class HiveService extends HouseScopedHiveService<Product> {
  HiveService() : super('products');

  /// Registrazione statica di tutti gli adapter usati da Hive.
  static void registerAdapter() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProductAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(HouseAdapter());
    }
  }

  // --- PRODOTTI (Per-Casa) ---
  List<Product> getAllProducts() => getAll();

  Future<void> addProduct(Product product) async => await put(product.id, product);

  Future<void> updateProduct(Product product) async => await product.save();

  Future<void> deleteProduct(String id) async => await delete(id);

  // --- CASE (Globali) ---

  /// Recupera tutte le case salvate ordinate per posizione[cite: 7].
  /// Se il database è vuoto al primo avvio, crea la casa di default "Casa 1"[cite: 7].
  List<House> getAllHouses() {
    final box = Hive.box<House>('houses');
    if (box.isEmpty) {
      final defaultHouse = House(
        id: '1',
        nome: 'Casa 1',
        ordine: 0,
      );
      box.put(defaultHouse.id, defaultHouse);
    }
    final houses = box.values.toList();
    houses.sort((a, b) => a.ordine.compareTo(b.ordine));
    return houses;
  }

  /// Salva o aggiorna un'istanza di Casa nel box globale.
  Future<void> addHouse(House house) async {
    final box = Hive.box<House>('houses');
    await box.put(house.id, house);
  }
}