import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nome;

  @HiveField(2)
  double quantita;

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