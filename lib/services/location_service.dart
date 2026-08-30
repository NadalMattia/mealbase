import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/location.dart';
import 'house_scoped_hive_service.dart';

class LocationService extends HouseScopedHiveService<Location> {
  LocationService() : super('locations');

  static void registerAdapter() {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(LocationAdapter());
    }
  }

  @override
  Future<void> onHouseSwitched() async {
    await _seedDefaultsIfEmpty();
  }

  Future<void> _seedDefaultsIfEmpty() async {
    if (box.isNotEmpty) return;
    const defaults = ['Frigo', 'Dispensa', 'Freezer'];
    for (var i = 0; i < defaults.length; i++) {
      final loc = Location(id: const Uuid().v4(), nome: defaults[i], ordine: i);
      await put(loc.id, loc);
    }
  }

  @override
  List<Location> getAll() {
    final list = super.getAll();
    list.sort((a, b) => a.ordine.compareTo(b.ordine));
    return list;
  }

  Future<void> addLocation(String nome) async {
    final existing = super.getAll();
    final maxOrdine = existing.isEmpty
        ? -1
        : existing.map((l) => l.ordine).reduce((a, b) => a > b ? a : b);
    final loc = Location(id: const Uuid().v4(), nome: nome, ordine: maxOrdine + 1);
    await put(loc.id, loc);
  }

  Future<void> deleteLocation(String id) async => await delete(id);

  Future<void> reorder(List<Location> newOrder) async {
    for (var i = 0; i < newOrder.length; i++) {
      newOrder[i].ordine = i;
      await newOrder[i].save();
    }
  }
}
