import 'dart:io';
import 'package:flutter/material.dart';

/// Mostra un'immagine che può essere:
/// - un path di file locale (foto scattata/scelta dall'utente,
///   eventualmente resa persistente da `ImageStorageService`);
/// - un URL remoto (foto di Open Food Facts trovata scansionando un
///   barcode, che inizia sempre con "http");
/// - assente (path nullo/vuoto).
///
/// PRIMA: questa stessa distinzione ("il path inizia con http?") e i
/// relativi `Image.network`/`Image.file` con gestione errori erano
/// duplicati, con leggere variazioni, in tre punti diversi:
/// `ProductImagePicker._buildImage()`, `ProductCard._buildImage()` e
/// `house_list_screen.dart` (`_buildHouseImage`, che tra l'altro usava
/// `File(...).existsSync()` — una chiamata sincrona al filesystem dentro
/// `build()`, non ideale). Tre implementazioni della stessa logica
/// significavano tre punti da tenere allineati se in futuro si voleva
/// cambiare comportamento (es. aggiungere caching, un loader, ecc.).
///
/// ORA: un solo widget centralizza "che tipo di path è" e come mostrarlo.
/// Ogni chiamante resta libero di personalizzare l'aspetto del
/// placeholder/errore passando [placeholderBuilder], così l'aspetto
/// visivo di ogni schermata resta invariato rispetto a prima.
class SmartImage extends StatelessWidget {
  /// Path locale o URL remoto dell'immagine. Se nullo/vuoto viene
  /// mostrato direttamente il placeholder.
  final String? path;

  /// Come adattare l'immagine nello spazio disponibile.
  final BoxFit fit;

  /// Costruisce il widget da mostrare quando non c'è un'immagine (path
  /// nullo/vuoto).
  final WidgetBuilder placeholderBuilder;

  /// Costruisce il widget da mostrare quando il caricamento fallisce
  /// (file mancante, URL non raggiungibile, ecc.). Se non specificato,
  /// viene riusato [placeholderBuilder]: molti chiamanti non hanno
  /// bisogno di distinguere i due casi.
  final WidgetBuilder? errorBuilder;

  /// Se true, mostra un piccolo indicatore di caricamento centrale mentre
  /// un'immagine remota sta scaricando (utile per gli avatar dove
  /// l'attesa è più visibile; non necessario nelle griglie di card dove
  /// le immagini sono più piccole e numerose).
  final bool showNetworkLoadingIndicator;

  const SmartImage({
    super.key,
    required this.path,
    required this.placeholderBuilder,
    this.errorBuilder,
    this.fit = BoxFit.cover,
    this.showNetworkLoadingIndicator = false,
  });

  /// true se [path] è un URL remoto (Open Food Facts) invece che un file
  /// locale sul device.
  static bool isRemote(String? path) =>
      path != null && (path.startsWith('http://') || path.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.trim().isEmpty) {
      return placeholderBuilder(context);
    }

    final onError = errorBuilder ?? placeholderBuilder;

    if (isRemote(path)) {
      return Image.network(
        path!,
        fit: fit,
        loadingBuilder: !showNetworkLoadingIndicator
            ? null
            : (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
        errorBuilder: (context, error, stackTrace) => onError(context),
      );
    }

    // File locale: usiamo errorBuilder invece di controllare
    // `File(path).existsSync()` prima di costruire il widget. Un controllo
    // sincrono sul filesystem dentro build() (come faceva in precedenza
    // house_list_screen.dart) può causare micro-scatti sulla UI; lasciare
    // che sia Image.file a segnalare l'errore è sia più corretto che più
    // performante.
    return Image.file(
      File(path!),
      fit: fit,
      errorBuilder: (context, error, stackTrace) => onError(context),
    );
  }
}
