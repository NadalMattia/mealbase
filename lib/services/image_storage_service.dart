import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Gestione centralizzata delle immagini "locali" (scattate con la
/// fotocamera o scelte dalla libreria) associate a case, prodotti e
/// articoli della lista spesa.
///
/// Questo servizio copia ogni immagine scelta dall'utente in una
/// sottocartella persistente e dedicata (`mealbase_images/`) dentro la
/// directory documenti dell'app, con un nome file univoco (uuid), e offre
/// un metodo per ripulire un'immagine non più referenziata.
///
/// Le immagini "remote" (URL Open Food Facts, che iniziano con "http",
/// mostrate quando si scansiona un barcode) non vengono mai toccate da
/// questo servizio: restano un link esterno, non c'è nessun file locale da
/// copiare o cancellare finché l'utente non sceglie esplicitamente una
/// foto propria.
class ImageStorageService {
  ImageStorageService._();

  /// Nome della sottocartella (dentro ApplicationDocumentsDirectory) in cui
  /// vengono copiate tutte le immagini scelte dall'utente.
  static const String _folderName = 'mealbase_images';

  /// Copia il file puntato da [pickedPath] (path temporaneo restituito da
  /// `image_picker`) in una posizione persistente dell'app e ritorna il
  /// nuovo path da salvare nel modello (Product/House/ShoppingItem).
  ///
  /// Se qualcosa va storto (file non più leggibile, storage non
  /// disponibile, ecc.) ritorna semplicemente [pickedPath] invariato,
  /// invece di lanciare un'eccezione: è meglio salvare un'immagine
  /// potenzialmente instabile piuttosto che bloccare l'utente nel bel
  /// mezzo del salvataggio di un prodotto.
  static Future<String> persistLocalImage(String pickedPath) async {
    try {
      final sourceFile = File(pickedPath);
      if (!await sourceFile.exists()) return pickedPath;

      final docsDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${docsDir.path}/$_folderName');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // Manteniamo l'estensione originale (jpg/png/heic/...) così il
      // sistema operativo continua a riconoscere correttamente il tipo di
      // file; se per qualche motivo non c'è un'estensione, ripieghiamo su
      // 'jpg' che è il formato più comune restituito da image_picker.
      final hasExtension = pickedPath.contains('.');
      final extension = hasExtension ? pickedPath.split('.').last : 'jpg';
      final newPath = '${targetDir.path}/${const Uuid().v4()}.$extension';

      await sourceFile.copy(newPath);
      return newPath;
    } catch (_) {
      return pickedPath;
    }
  }

  /// Elimina il file locale puntato da [imagePath], se esiste.
  ///
  /// Ignora silenziosamente:
  /// - i path nulli o vuoti (niente da cancellare);
  /// - i path remoti che iniziano con "http" (immagini Open Food Facts:
  ///   non sono file nostri, non vanno toccati).

  static Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    if (imagePath.startsWith('http')) return;

    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Cancellazione best-effort: si ignora volutamente l'errore.
    }
  }
}
