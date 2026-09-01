import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/shopping_item.dart';

class ShoppingListProvider with ChangeNotifier {
  Box<ShoppingItem>? _box;
  String _currentHouse = 'Casa 1';
  final Set<String> _pendingDeleteIds = {};

  ShoppingListProvider() {
    _initBox();
  }

  Future<void> _initBox() async {
    final boxName = 'shopping_box_${_currentHouse.replaceAll(' ', '_').toLowerCase()}';
    _box = await Hive.openBox<ShoppingItem>(boxName);
    notifyListeners();
  }

  Future<void> switchHouse(String houseName) async {
    if (_currentHouse == houseName && _box != null && _box!.isOpen) return;

    _currentHouse = houseName;
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
    await _initBox();
  }

  List<ShoppingItem> get items =>
      (_box?.values.toList() ?? []).where((item) => !_pendingDeleteIds.contains(item.id)).toList();

  List<ShoppingItem> get daAcquistare =>
      items.where((item) => !item.preso).toList();

  List<ShoppingItem> get giaPreso =>
      items.where((item) => item.preso).toList();

  void addItem(String nome, {String? marca, String? imagePath}) {
    final newItem = ShoppingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nome,
      marca: marca,
      imagePath: imagePath,
      preso: false,
    );

    _box?.put(newItem.id, newItem);
    notifyListeners();
  }

  /// Nasconde temporaneamente l'elemento
  void hideItem(String id) {
    _pendingDeleteIds.add(id);
    notifyListeners();
  }

  /// Annulla l'eliminazione rendendo di nuovo visibile l'elemento
  void cancelDeleteItem(String id) {
    _pendingDeleteIds.remove(id);
    notifyListeners();
  }

  /// Elimina definitivamente il prodotto da Hive
  void confirmDeleteItem(String id) {
    _pendingDeleteIds.remove(id);
    _box?.delete(id);
    notifyListeners();
  }

  void updateItem(ShoppingItem item) {
    item.save();
    notifyListeners();
  }

  void toggleItem(ShoppingItem item) {
    item.preso = !item.preso;
    item.save();
    notifyListeners();
  }

  void deleteItem(String id) {
    _box?.delete(id);
    notifyListeners();
  }
}