import 'package:hive/hive.dart';

part 'house.g.dart';

/// Rappresenta una "casa" (spazio abitativo) dell'utente.
///
/// Prima le case create dall'utente vivevano solo in uno State locale di
/// `HouseListScreen` (una `List<String>` in memoria): venivano perse ad
/// ogni riavvio dell'app, mentre tutto il contenuto (prodotti, spesa,
/// location) al loro interno restava invece salvato su Hive. Con questo
/// model anche l'elenco delle case è persistito, in modo coerente con il
/// resto dei dati.
@HiveType(typeId: 3)
class House extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nome;

  @HiveField(2)
  int ordine;

  House({required this.id, required this.nome, required this.ordine});
}
