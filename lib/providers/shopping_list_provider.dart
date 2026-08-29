import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_item.dart';
import '../services/shopping_list_service.dart';

class ShoppingListProvider extends ChangeNotifier {
  final ShoppingListService _service = ShoppingListService();
  List<ShoppingItem> _items = [];

  ShoppingListProvider() {
    // Rimosso loadItems() dal costruttore
  }

  List<ShoppingItem> get daAcquistare =>
      _items.where((i) => !i.inCarrello).toList();

  List<ShoppingItem> get giaPreso =>
      _items.where((i) => i.inCarrello).toList();

  Future<void> switchHouse(String houseName) async {
    await _service.switchHouse(houseName);
    loadItems();
  }

  void loadItems() {
    _items = _service.getAll();
    notifyListeners();
  }

  Future<void> addItem(String nome) async {
    if (nome.trim().isEmpty) return;
    final item = ShoppingItem(id: const Uuid().v4(), nome: nome.trim());
    await _service.addItem(item);
    loadItems();
  }

  Future<void> toggleItem(ShoppingItem item) async {
    item.inCarrello = !item.inCarrello;
    await _service.updateItem(item);
    loadItems();
  }

  Future<void> deleteItem(String id) async {
    await _service.deleteItem(id);
    loadItems();
  }
}