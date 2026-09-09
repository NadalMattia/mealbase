import 'package:hive/hive.dart';

part 'house.g.dart';

@HiveType(typeId: 3)
/// Una casa dell'utente. Il suo [id] è la chiave con cui vengono nominati
/// i box Hive di dispensa, spazi e lista della spesa.
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