import 'package:flutter/foundation.dart';
import '../models/house.dart';
import '../models/location.dart';
import '../services/location_service.dart';

/// Stato degli spazi della dispensa (Frigo, Freezer, ...) della casa
/// selezionata: alimenta le tab della dispensa e il menu "alloca in" del
/// form prodotto.
class LocationProvider extends ChangeNotifier {
  final LocationService _service = LocationService();
  List<Location> _locations = [];

  List<Location> get locations => _locations;

  /// Carica gli spazi di [house], creando i predefiniti se la casa è nuova.
  ///
  /// Il box viene aperto per [House.id]; il nome serve solo alla migrazione
  /// di eventuali dati salvati con schemi di naming precedenti.
  Future<void> switchHouse(House house) async {
    await _service.switchHouse(house.id, legacyName: house.nome);
    loadLocations();
  }

  /// Rilegge gli spazi da Hive e notifica la UI.
  void loadLocations() {
    _locations = _service.getAll();
    notifyListeners();
  }

  /// Crea uno spazio in coda all'elenco.
  ///
  /// Ritorna `false` senza modificare nulla se il nome è vuoto o duplica
  /// uno spazio esistente, così che la UI possa mostrare l'errore.
  Future<bool> addLocation(String nome) async {
    if (nome.trim().isEmpty) return false;
    final added = await _service.addLocation(nome.trim());
    if (added) loadLocations();
    return added;
  }

  Future<void> deleteLocation(String id) async {
    await _service.deleteLocation(id);
    loadLocations();
  }

  /// Riordina gli spazi dopo un drag & drop.
  ///
  /// [newIndex] è la posizione finale già corretta: la schermata usa
  /// `onReorderItem`, che a differenza del deprecato `onReorder` tiene
  /// conto da sé dell'elemento rimosso dalla lista.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final updated = List<Location>.from(_locations);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    await _service.reorder(updated);
    loadLocations();
  }
}