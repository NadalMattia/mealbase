import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
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

  /// Crea una nuova casa.
  ///
  /// L'id viene generato con `uuid` (come già avviene per `Location` e,
  /// dopo il refactor, per `ShoppingItem`/`Product`) invece che con
  /// `DateTime.now().millisecondsSinceEpoch`: elimina il, seppur remoto,
  /// rischio di collisioni tra id creati nello stesso istante e rende la
  /// generazione degli id uniforme in tutta l'app.

  Future<void> addHouse(String nome, {String? imagePath}) async {
    final id = const Uuid().v4();
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