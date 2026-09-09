import 'package:hive_flutter/hive_flutter.dart';
import '../models/shopping_item.dart';
import 'house_scoped_hive_service.dart';

/// Accesso agli articoli della lista della spesa di una casa.
class ShoppingListService extends HouseScopedHiveService<ShoppingItem> {
  ShoppingListService()
      : super(
          'shopping_items',
          cloneForMigration: (i) => ShoppingItem(
            id: i.id,
            nome: i.nome,
            preso: i.preso,
            imagePath: i.imagePath,
            marca: i.marca,
            quantita: i.quantita,
          ),
        );

  static void registerAdapter() {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ShoppingItemAdapter());
    }
  }

  /// Oltre allo schema `shopping_items_<nome casa>` gestito dalla classe
  /// base, questo servizio controlla anche `shopping_box_<nome casa>`,
  /// usato prima che la lista della spesa passasse a
  /// [HouseScopedHiveService].
  @override
  Future<void> migrateLegacyBoxesIfNeeded(String legacyName) async {
    await super.migrateLegacyBoxesIfNeeded(legacyName);
    if (box.isNotEmpty) return;

    final veryLegacyBoxName =
        'shopping_box_${legacyName.replaceAll(' ', '_').toLowerCase()}';
    await migrateFromBoxNamed(veryLegacyBoxName);
  }

  Future<void> addItem(ShoppingItem item) async => await put(item.id, item);

  /// Persiste le modifiche fatte in-place su [item], che è lo stesso
  /// riferimento restituito da [getAll].
  Future<void> updateItem(ShoppingItem item) async => await item.save();

  Future<void> deleteItem(String id) async => await delete(id);
}
