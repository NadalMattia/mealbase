import 'package:flutter/foundation.dart';
import '../models/house.dart';
import '../services/house_service.dart';

class HouseProvider extends ChangeNotifier {
  final HouseService _service = HouseService();
  List<House> _houses = [];

  List<House> get houses => _houses;

  /// Va chiamato dopo che `HouseService.openBox()` è stato eseguito in
  /// main.dart (all'avvio dell'app), non nel costruttore, per restare
  /// coerenti con lo stesso pattern già usato dagli altri provider.
  void loadHouses() {
    _houses = _service.getAll();
    notifyListeners();
  }

  Future<void> addHouse(String nome) async {
    if (nome.trim().isEmpty) return;
    await _service.addHouse(nome.trim());
    loadHouses();
  }

  Future<void> deleteHouse(String id) async {
    await _service.deleteHouse(id);
    loadHouses();
  }
}
