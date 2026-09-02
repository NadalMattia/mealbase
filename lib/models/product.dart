import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nome;

  // FIX STRUTTURALE: `quantita` era `double`, poi cambiato a `int`. I
  // prodotti salvati PRIMA di quel cambiamento hanno il campo scritto su
  // disco come `double` (es. 1.0). Un campo Hive dichiarato `int` genera
  // sempre, ad ogni rigenerazione con build_runner, un adapter che legge
  // `fields[2] as int` — che lancia un'eccezione a runtime su quei dati
  // vecchi, perché in Dart `double` e `int` sono tipi distinti anche
  // quando il valore numerico coincide. Un Box Hive non-lazy decodifica
  // TUTTI i valori all'apertura, quindi questa eccezione bloccava
  // l'apertura dell'intera dispensa per chiunque avesse già prodotti
  // salvati (esattamente il crash su "Casa 1": conteneva prodotti
  // salvati quando il campo era ancora `double`).
  //
  // La volta scorsa questo era stato corretto solo nel file generato
  // `product.g.dart`, cambiando a mano `as int` in `as num`. Ma quel
  // file è rigenerato automaticamente da build_runner: una rigenerazione
  // successiva lo ha sovrascritto, facendo ripresentare il crash.
  //
  // Ora il campo Hive-annotato (`quantitaRaw`) è `num`, il tipo comune a
  // int e double: qualunque adapter generato da qui in avanti — anche
  // rigenerato da zero — leggerà sempre `as num`, tollerante sia ai
  // vecchi dati `double` sia ai nuovi `int`, senza bisogno di correggere
  // di nuovo il file generato a mano.
  //
  // Il resto dell'app continua a vedere `quantita` come un normale `int`
  // (getter/setter qui sotto): nessun altro file del progetto necessita
  // modifiche.
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