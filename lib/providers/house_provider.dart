import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/house.dart';
import '../services/house_service.dart';

/// Elenco delle case dell'utente.
///
/// A differenza degli altri provider non è scoperto per casa: le case sono
/// il livello che sta sopra, in un unico box globale.
class HouseProvider extends ChangeNotifier {
  final HouseService _houseService = HouseService();
  List<House> _houses = [];

  List<House> get houses => _houses;

  HouseProvider() {
    loadHouses();
  }

  /// Rilegge le case da Hive e notifica la UI.
  void loadHouses() {
    _houses = _houseService.getAllHouses();
    notifyListeners();
  }

  /// Crea una casa e la accoda all'elenco.
  ///
  /// L'id generato qui diventa la chiave dei box Hive della casa (vedi
  /// [HouseScopedHiveService]), quindi deve restare stabile per tutta la
  /// vita della casa anche se l'utente ne cambia il nome.
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