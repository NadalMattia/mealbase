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

  // FIX STRUTTURALE: `quantita` è un campo aggiunto DOPO che l'app era già
  // in uso. Gli articoli salvati prima di questa aggiunta non hanno
  // affatto il campo scritto su disco. Un campo Hive dichiarato `int`
  // (non nullable) genera sempre, ad ogni rigenerazione con build_runner,
  // un adapter che legge `fields[5] as int` — che lancia un'eccezione a
  // runtime quando il campo è assente (`fields[5]` vale `null` in quel
  // caso, e `null as int` fallisce). Come per `Product.quantita`
  // (vedi il commento lì per i dettagli), la volta scorsa questo era
  // stato corretto solo nel file generato `shopping_item.g.dart`, che
  // può essere sovrascritto da una rigenerazione futura.
  //
  // Ora il campo Hive-annotato (`quantitaRaw`) è nullable (`int?`):
  // qualunque adapter generato da qui in avanti leggerà sempre
  // `as int?`, che per un campo assente vale semplicemente `null` invece
  // di lanciare un'eccezione. Il resto dell'app continua a vedere
  // `quantita` come un normale `int` con default 1 (getter/setter qui
  // sotto): nessun altro file del progetto necessita modifiche.
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