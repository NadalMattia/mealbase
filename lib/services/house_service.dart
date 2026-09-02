import 'package:hive_flutter/hive_flutter.dart';
import '../models/house.dart';

class HouseService {
  static const String _boxName = 'houses';

  static void registerAdapter() {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(HouseAdapter());
    }
  }

  static Future<void> openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<House>(_boxName);
    }
  }

  List<House> getAllHouses() {
    final box = Hive.box<House>(_boxName);
    final houses = box.values.toList();
    houses.sort((a, b) => a.ordine.compareTo(b.ordine));
    return houses;
  }

  /// Salva o aggiorna un'istanza di Casa.
  Future<void> addHouse(House house) async {
    final box = Hive.box<House>(_boxName);
    await box.put(house.id, house);
  }
}