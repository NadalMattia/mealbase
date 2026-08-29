import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/location.dart';

class LocationService {
  String _boxName = 'locations';

  static void registerAdapter() {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(LocationAdapter());
    }
  }

  Future<void> switchHouse(String houseName) async {
    _boxName = 'locations_$houseName';
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Location>(_boxName);
    }
    await _seedDefaultsIfEmpty();
  }

  Future<void> _seedDefaultsIfEmpty() async {
    if (!Hive.isBoxOpen(_boxName)) return;
    final box = Hive.box<Location>(_boxName);
    if (box.isEmpty) {
      const defaults = ['Frigo', 'Dispensa', 'Freezer'];
      for (var i = 0; i < defaults.length; i++) {
        final loc = Location(id: const Uuid().v4(), nome: defaults[i], ordine: i);
        await box.put(loc.id, loc);
      }
    }
  }

  Box<Location> get _box => Hive.box<Location>(_boxName);

  List<Location> getAll() {
    if (!Hive.isBoxOpen(_boxName)) return [];
    final list = _box.values.toList();
    list.sort((a, b) => a.ordine.compareTo(b.ordine));
    return list;
  }

  Future<void> addLocation(String nome) async {
    final maxOrdine = _box.values.isEmpty
        ? -1 : _box.values.map((l) => l.ordine).reduce((a, b) => a > b ? a : b);
    final loc = Location(id: const Uuid().v4(), nome: nome, ordine: maxOrdine + 1);
    await _box.put(loc.id, loc);
  }

  Future<void> deleteLocation(String id) async => await _box.delete(id);

  Future<void> reorder(List<Location> newOrder) async {
    for (var i = 0; i < newOrder.length; i++) {
      newOrder[i].ordine = i;
      await newOrder[i].save();
    }
  }
}