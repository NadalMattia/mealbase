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
