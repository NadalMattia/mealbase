import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/house.dart';

/// Gestisce l'elenco delle case dell'utente.
///
/// A differenza di [HiveService]/[LocationService]/[ShoppingListService],
/// che aprono un box *diverso per ogni casa*, qui il box è unico e globale
/// ('houses'): è l'elenco delle case stesse, quindi non può dipendere da
/// quale casa è selezionata. Per questo non estende
/// [HouseScopedHiveService] ma apre il proprio box una volta sola
/// all'avvio dell'app (vedi `main.dart`).
class HouseService {
  static const String boxName = 'houses';

  static void registerAdapter() {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(HouseAdapter());
    }
  }

  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<House>(boxName);
      await _seedDefaultsIfEmpty();
    }
  }

  static Future<void> _seedDefaultsIfEmpty() async {
    final box = Hive.box<House>(boxName);
    if (box.isNotEmpty) return;
    const defaults = ['Casa 1', 'Casa 2'];
    for (var i = 0; i < defaults.length; i++) {
      final house = House(id: const Uuid().v4(), nome: defaults[i], ordine: i);
      await box.put(house.id, house);
    }
  }

  Box<House> get _box => Hive.box<House>(boxName);

  List<House> getAll() {
    if (!Hive.isBoxOpen(boxName)) return [];
    final list = _box.values.toList();
    list.sort((a, b) => a.ordine.compareTo(b.ordine));
    return list;
  }

  Future<void> addHouse(String nome) async {
    final existing = getAll();
    final maxOrdine = existing.isEmpty
        ? -1
        : existing.map((h) => h.ordine).reduce((a, b) => a > b ? a : b);
    final house = House(id: const Uuid().v4(), nome: nome, ordine: maxOrdine + 1);
    await _box.put(house.id, house);
  }

  Future<void> deleteHouse(String id) async => await _box.delete(id);
}
