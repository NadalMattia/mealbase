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

  Future<void> addItem(ShoppingItem item) async => await put(item.id, item);

  Future<void> updateItem(ShoppingItem item) async => await item.save();

  Future<void> deleteItem(String id) async => await delete(id);
}
