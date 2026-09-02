import 'dart:io';
import 'package:flutter/material.dart';

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

    return Image.file(
      File(path!),
      fit: fit,
      errorBuilder: (context, error, stackTrace) => onError(context),
    );
  }
}
