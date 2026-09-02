import 'package:hive/hive.dart';

part 'shopping_item.g.dart';

@HiveType(typeId: 1)
class ShoppingItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nome;

  @HiveField(2)
  bool preso;

  @HiveField(3)
  String? imagePath;

  @HiveField(4)
  String? marca;

  @HiveField(5)
  int? quantitaRaw;

  int get quantita => quantitaRaw ?? 1;
  set quantita(int value) => quantitaRaw = value;

  ShoppingItem({
    required this.id,
    required this.nome,
    this.preso = false,
    this.imagePath,
    this.marca,
    int quantita = 1,
  }) : quantitaRaw = quantita;
}