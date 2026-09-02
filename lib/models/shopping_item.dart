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
  int quantita;

  ShoppingItem({
    required this.id,
    required this.nome,
    this.preso = false,
    this.imagePath,
    this.marca,
    this.quantita = 1,
  });
}