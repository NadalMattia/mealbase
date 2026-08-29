import 'package:hive/hive.dart';

part 'shopping_item.g.dart';

@HiveType(typeId: 1)
class ShoppingItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nome;

  @HiveField(2)
  bool inCarrello;

  ShoppingItem({
    required this.id,
    required this.nome,
    this.inCarrello = false,
  });
}