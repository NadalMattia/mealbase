import 'package:hive/hive.dart';

part 'house.g.dart';

@HiveType(typeId: 3)
class House extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nome;

  @HiveField(2)
  int ordine;

  @HiveField(3)
  String? imagePath;

  House({
    required this.id,
    required this.nome,
    required this.ordine,
    this.imagePath,
  });
}