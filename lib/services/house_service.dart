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

  /// Recupera tutte le case salvate, ordinate per posizione.
  ///
  /// Un utente nuovo (box vuoto al primo avvio) parte senza nessuna casa
  /// preimpostata: vedrà semplicemente la schermata "Le tue case" vuota,
  /// con il pulsante "Aggiungi una nuova casa" — che `house_list_screen.dart`
  /// gestisce già correttamente per una lista vuota, senza bisogno di
  /// nessuna modifica lì.
  ///
  /// PRIMA: se il box era vuoto veniva creata automaticamente una casa
  /// di default chiamata "Casa 1". Comodo per continuare a sviluppare
  /// senza dover creare una casa ad ogni test, ma un'esperienza poco
  /// pulita per un utente reale che installa l'app per la prima volta:
  /// si ritrovava una casa già presente con un nome generico invece di
  /// una schermata di benvenuto pulita.
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