import 'package:hive/hive.dart';

part 'location.g.dart';

@HiveType(typeId: 2)
class Location extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nome;

  @HiveField(2)
  int ordine;

  Location({required this.id, required this.nome, required this.ordine});
}