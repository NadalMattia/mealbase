import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Gestione centralizzata delle immagini "locali" (scattate con la
/// fotocamera o scelte dalla libreria) associate a case, prodotti e
/// articoli della lista spesa.
///
/// PRIMA: ogni punto dell'app che apriva `image_picker`
/// (`ProductImagePicker`, il dialog "Nuova casa" in `house_list_screen`)
/// salvava direttamente il path temporaneo restituito dal plugin
/// (`XFile.path`) dentro `imagePath`. Due problemi concreti:
///
///  1. Su iOS in particolare, quel path punta a un file nella cache
///     dell'app: non è garantito che sopravviva a lungo, quindi
///     l'immagine poteva sparire dopo un po' senza che l'utente avesse
///     fatto nulla.
///  2. Nessuno cancellava mai il file quando il prodotto/casa/articolo
///     veniva eliminato, o quando l'immagine veniva sostituita con
///     un'altra: i file restavano orfani sullo storage del device
///     all'infinito.
///
/// ORA: questo servizio copia ogni immagine scelta dall'utente in una
/// sottocartella persistente e dedicata (`mealbase_images/`) dentro la
/// directory documenti dell'app, con un nome file univoco (uuid), e offre
/// un metodo per ripulire un'immagine non più referenziata.
///
/// Le immagini "remote" (URL Open Food Facts, che iniziano con "http",
/// mostrate quando si scansiona un barcode) non vengono mai toccate da
/// questo servizio: restano un link esterno, non c'è nessun file locale da
/// copiare o cancellare finché l'utente non sceglie esplicitamente una
/// foto propria.
///
/// ATTENZIONE - DIPENDENZA DA AGGIUNGERE: questo servizio usa il pacchetto
/// `path_provider`, che non era tra le dipendenze già presenti nel
/// progetto. Va aggiunto a `pubspec.yaml`:
///   dependencies:
///     path_provider: ^2.1.0
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
  ///
  /// La cancellazione è "best effort": eventuali errori (permessi, file
  /// già rimosso da un'altra parte, ecc.) vengono ignorati per non
  /// bloccare il flusso dell'utente (es. l'eliminazione di un prodotto
  /// deve riuscire comunque, anche se la pulizia del file immagine
  /// fallisce).
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
