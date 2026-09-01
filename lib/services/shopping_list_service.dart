import 'package:hive_flutter/hive_flutter.dart';
import '../models/shopping_item.dart';
import 'house_scoped_hive_service.dart';

class ShoppingListService extends HouseScopedHiveService<ShoppingItem> {
  ShoppingListService() : super('shopping_items');

  static void registerAdapter() {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ShoppingItemAdapter());
    }
  }

  @override
  Future<void> onHouseSwitched() async {
    await _migrateFromLegacyBoxIfNeeded();
  }

  /// Migrazione una tantum dal vecchio schema di naming dei box.
  ///
  /// PRIMA: `ShoppingListProvider` non usava questo servizio. Apriva da
  /// solo un box Hive con un nome diverso e "fatto in casa":
  /// `shopping_box_<nome_casa_minuscolo_con_underscore>` (es. per la casa
  /// "Casa 1" diventava `shopping_box_casa_1`).
  ///
  /// ORA: passando `ShoppingListProvider` su questa classe (che eredita da
  /// `HouseScopedHiveService`, la stessa base già usata da `HiveService` e
  /// `LocationService`), il box per una casa si chiama invece
  /// `shopping_items_<nome_casa_esatto>` (es. `shopping_items_Casa 1`).
  ///
  /// Senza questo passaggio, gli utenti che avevano già una lista della
  /// spesa salvata la vedrebbero sparire (i dati resterebbero nel vecchio
  /// box, mai più aperto da nessuno). Per evitarlo: se il box "nuovo" per
  /// la casa corrente è vuoto, controlliamo se esiste il vecchio box e, in
  /// caso affermativo, copiamo tutti gli articoli nel nuovo box. Il
  /// vecchio box NON viene cancellato (lo lasciamo semplicemente inutilizzato):
  /// è una scelta prudente, per non perdere dati in caso la migrazione
  /// venga eseguita più volte o interrotta a metà.
  Future<void> _migrateFromLegacyBoxIfNeeded() async {
    if (box.isNotEmpty) return; // il nuovo box ha già dei dati: niente da fare

    final currentHouseName = houseName;
    if (currentHouseName == null) return;

    final legacyBoxName =
        'shopping_box_${currentHouseName.replaceAll(' ', '_').toLowerCase()}';

    final legacyBoxExists = await Hive.boxExists(legacyBoxName);
    if (!legacyBoxExists) return;

    final legacyBox = Hive.isBoxOpen(legacyBoxName)
        ? Hive.box<ShoppingItem>(legacyBoxName)
        : await Hive.openBox<ShoppingItem>(legacyBoxName);

    for (final item in legacyBox.values) {
      await put(item.id, item);
    }
  }

  Future<void> addItem(ShoppingItem item) async => await put(item.id, item);

  Future<void> updateItem(ShoppingItem item) async => await item.save();

  Future<void> deleteItem(String id) async => await delete(id);
}
