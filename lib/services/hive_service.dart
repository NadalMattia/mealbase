import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import 'house_scoped_hive_service.dart';

/// Servizio Hive per i prodotti della dispensa, scoperto "per casa" tramite
/// [HouseScopedHiveService].
///
/// NOTA STORICA: questa classe conteneva in precedenza anche `getAllHouses()`
/// e `addHouse()`, una copia identica (codice morto, mai chiamato da
/// nessuno screen/provider) dei metodi già presenti in [HouseService], che
/// è l'unico punto reale usato dall'app per gestire le case (box globale
/// 'houses', non scoperto per casa). Duplicare quella logica qui era
/// fonte di confusione e rischio di bug futuri (le due copie avrebbero
/// potuto divergere), quindi è stata rimossa: per tutto ciò che riguarda
/// le case, fare riferimento a [HouseService]/[HouseProvider].
class HiveService extends HouseScopedHiveService<Product> {
  HiveService() : super('products');

  /// Registra l'adapter Hive del modello [Product].
  ///
  /// L'adapter di [House] viene registrato separatamente da
  /// `HouseService.registerAdapter()` (chiamato in `main.dart`): prima
  /// veniva registrato anche qui, in modo ridondante.
  static void registerAdapter() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProductAdapter());
    }
  }

  // --- PRODOTTI (Per-Casa) ---
  List<Product> getAllProducts() => getAll();

  Future<void> addProduct(Product product) async => await put(product.id, product);

  Future<void> updateProduct(Product product) async => await product.save();

  Future<void> deleteProduct(String id) async => await delete(id);
}