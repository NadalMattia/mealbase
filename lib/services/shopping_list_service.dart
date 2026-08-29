import 'package:hive_flutter/hive_flutter.dart';
import '../models/shopping_item.dart';

class ShoppingListService {
  String _boxName = 'shopping_items';

  static void registerAdapter() {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ShoppingItemAdapter());
    }
  }

  Future<void> switchHouse(String houseName) async {
    _boxName = 'shopping_items_$houseName';
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<ShoppingItem>(_boxName);
    }
  }

  Box<ShoppingItem> get _box => Hive.box<ShoppingItem>(_boxName);

  List<ShoppingItem> getAll() => Hive.isBoxOpen(_boxName) ? _box.values.toList() : [];

  Future<void> addItem(ShoppingItem item) async => await _box.put(item.id, item);
  Future<void> updateItem(ShoppingItem item) async => await item.save();
  Future<void> deleteItem(String id) async => await _box.delete(id);
}