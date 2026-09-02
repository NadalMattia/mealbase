import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nome;

  // ATTENZIONE: campo Hive-annotato direttamente come `int`. Se esistono
  // prodotti salvati quando questo campo era `double` (versioni precedenti
  // dell'app), la lettura da Hive lancia un'eccezione ("type 'double' is
  // not a subtype of type 'int'"), bloccando l'apertura dell'intera
  // dispensa per quella casa. Se non serve più questa retrocompatibilità
  // (es. dati vecchi già rimossi/migrati), il campo è corretto così com'è.
  @HiveField(2)
  int quantita;

  @HiveField(3)
  String unita;

  @HiveField(4)
  String categoria;

  @HiveField(5)
  String posizione;

  @HiveField(6)
  DateTime dataAcquisto;

  @HiveField(7)
  DateTime? dataScadenza;

  @HiveField(8)
  String? imagePath;

  @HiveField(9)
  String? marca;

  Product({
    required this.id,
    required this.nome,
    required this.quantita,
    required this.unita,
    required this.categoria,
    required this.posizione,
    required this.dataAcquisto,
    this.dataScadenza,
    this.imagePath,
    this.marca,
  });
}