import 'package:hive_flutter/hive_flutter.dart';
import '../models/shopping_item.dart';

class ShoppingListService {
  static const String boxName = 'shopping_items';

  static Future<void> init() async {
    Hive.registerAdapter(ShoppingItemAdapter());
    await Hive.openBox<ShoppingItem>(boxName);
  }

  Box<ShoppingItem> get _box => Hive.box<ShoppingItem>(boxName);

  List<ShoppingItem> getAll() => _box.values.toList();

  Future<void> addItem(ShoppingItem item) async {
    await _box.put(item.id, item);
  }

  Future<void> updateItem(ShoppingItem item) async {
    await item.save();
  }

  Future<void> deleteItem(String id) async {
    await _box.delete(id);
  }
}