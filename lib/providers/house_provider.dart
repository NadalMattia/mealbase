import 'package:flutter/foundation.dart';
import '../models/house.dart';
import '../services/house_service.dart';

class HouseProvider extends ChangeNotifier {
  final HouseService _houseService = HouseService();
  List<House> _houses = [];

  List<House> get houses => _houses;

  HouseProvider() {
    loadHouses();
  }

  void loadHouses() {
    _houses = _houseService.getAllHouses();
    notifyListeners();
  }

  Future<void> addHouse(String nome, {String? imagePath}) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final house = House(
      id: id,
      nome: nome,
      ordine: _houses.length,
      imagePath: imagePath,
    );
    await _houseService.addHouse(house);
    loadHouses();
  }
}