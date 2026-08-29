import 'package:flutter/foundation.dart';
import '../models/location.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _service = LocationService();
  List<Location> _locations = [];

  LocationProvider() {
    loadLocations();
  }

  List<Location> get locations => _locations;

  void loadLocations() {
    _locations = _service.getAll();
    notifyListeners();
  }

  Future<void> addLocation(String nome) async {
    if (nome.trim().isEmpty) return;
    await _service.addLocation(nome.trim());
    loadLocations();
  }

  Future<void> deleteLocation(String id) async {
    await _service.deleteLocation(id);
    loadLocations();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final updated = List<Location>.from(_locations);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    await _service.reorder(updated);
    loadLocations();
  }
}