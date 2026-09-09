import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import 'house_scoped_hive_service.dart';

/// Accesso ai prodotti della dispensa, uno box Hive per casa.
///
/// Le case in quanto tali sono gestite da [HouseService], che lavora su un
/// box globale non scoperto per casa.
class HiveService extends HouseScopedHiveService<Product> {
  HiveService()
      : super(
          'products',
          cloneForMigration: (p) => Product(
            id: p.id,
            nome: p.nome,
            quantita: p.quantita,
            unita: p.unita,
            categoria: p.categoria,
            posizione: p.posizione,
            dataAcquisto: p.dataAcquisto,
            dataScadenza: p.dataScadenza,
            imagePath: p.imagePath,
            marca: p.marca,
          ),
        );

  /// Registra l'adapter del modello [Product]. Va chiamata una volta in
  /// `main.dart`, prima di aprire qualsiasi box che contenga prodotti.
  static void registerAdapter() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProductAdapter());
    }
  }

  List<Product> getAllProducts() => getAll();

  Future<void> addProduct(Product product) async => await put(product.id, product);

  /// Persiste le modifiche fatte in-place su [product], che è lo stesso
  /// riferimento restituito da [getAllProducts].
  Future<void> updateProduct(Product product) async => await product.save();

  Future<void> deleteProduct(String id) async => await delete(id);
}
