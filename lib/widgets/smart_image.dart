import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Immagine che sceglie da sola come caricarsi.
///
/// Un percorso che inizia con `http` è un'immagine remota di Open Food
/// Facts, tutto il resto è un file locale. Placeholder ed errore sono
/// forniti dal chiamante, così ogni contesto può renderli con le proprie
/// dimensioni e il proprio stile.
///
/// Le immagini remote passano da [CachedNetworkImage], che le conserva su
/// disco: senza cache ogni apertura della dispensa le riscaricherebbe e
/// senza rete le card dei prodotti scansionati resterebbero vuote.
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
      return CachedNetworkImage(
        imageUrl: path!,
        fit: fit,
        // Con l'indicatore disattivato si lascia lo spazio vuoto durante il
        // download: nelle griglie di card, dove le immagini sono piccole e
        // numerose, una manciata di rotelle darebbe più disturbo che
        // informazione.
        placeholder: !showNetworkLoadingIndicator
            ? null
            : (context, url) => const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
        errorWidget: (context, url, error) => onError(context),
      );
    }

    return Image.file(
      File(path!),
      fit: fit,
      errorBuilder: (context, error, stackTrace) => onError(context),
    );
  }
}
