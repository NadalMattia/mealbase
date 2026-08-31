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

  // Percorso locale (foto scattata/scelta dall'utente) oppure URL remoto
  // (immagine trovata su Open Food Facts durante la scansione barcode).
  @HiveField(3)
  String? imagePath;

  ShoppingItem({
    required this.id,
    required this.nome,
    this.inCarrello = false,
    this.imagePath,
  });
}
