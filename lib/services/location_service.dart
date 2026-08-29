import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/location.dart';

class LocationService {
  static const String boxName = 'locations';

  static Future<void> init() async {
    Hive.registerAdapter(LocationAdapter());
    await Hive.openBox<Location>(boxName);
    await _seedDefaultsIfEmpty();
  }

  static Future<void> _seedDefaultsIfEmpty() async {
    final box = Hive.box<Location>(boxName);
    if (box.isEmpty) {
      const defaults = ['Frigo', 'Dispensa', 'Freezer'];
      for (var i = 0; i < defaults.length; i++) {
        final loc = Location(id: const Uuid().v4(), nome: defaults[i], ordine: i);
        await box.put(loc.id, loc);
      }
    }
  }

  Box<Location> get _box => Hive.box<Location>(boxName);

  List<Location> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) => a.ordine.compareTo(b.ordine));
    return list;
  }

  Future<void> addLocation(String nome) async {
    final maxOrdine = _box.values.isEmpty
        ? -1
        : _box.values.map((l) => l.ordine).reduce((a, b) => a > b ? a : b);
    final loc = Location(id: const Uuid().v4(), nome: nome, ordine: maxOrdine + 1);
    await _box.put(loc.id, loc);
  }

  Future<void> deleteLocation(String id) async {
    await _box.delete(id);
  }

  Future<void> reorder(List<Location> newOrder) async {
    for (var i = 0; i < newOrder.length; i++) {
      newOrder[i].ordine = i;
      await newOrder[i].save();
    }
  }
}