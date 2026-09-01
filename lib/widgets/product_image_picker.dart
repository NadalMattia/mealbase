import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_storage_service.dart';
import '../theme/app_theme.dart';

/// Avatar circolare con badge fotocamera per aggiungere/cambiare la foto
/// di un prodotto.
///
/// Prima questo bottone era solo scenografico in tre punti diversi
/// (`product_form_screen`, `shopping_scanner_screen`,
/// `shopping_item_edit_screen`): un tap mostrava uno snackbar "in arrivo" e
/// basta. Ora apre davvero la fotocamera o la libreria foto tramite
/// `image_picker` e restituisce il percorso del file scelto.
///
/// [imagePath] accetta sia un percorso file locale (foto scattata/scelta
/// dall'utente) sia un URL remoto (foto trovata su Open Food Facts durante
/// la scansione barcode): il widget capisce da solo quale dei due
/// mostrare.
class ProductImagePicker extends StatelessWidget {
  final String? imagePath;
  final ValueChanged<String> onImagePicked;
  final double size;

  const ProductImagePicker({
    super.key,
    required this.imagePath,
    required this.onImagePicked,
    this.size = 140,
  });

  bool get _isRemote => imagePath != null && imagePath!.startsWith('http');

  Future<void> _showPickerSheet(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Scatta una foto'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Scegli dalla libreria'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !context.mounted) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        // Copiamo subito il file in una cartella persistente dell'app
        // (vedi ImageStorageService per i dettagli sul "perché") invece di
        // tenere il path temporaneo restituito da image_picker, che su
        // alcune piattaforme non è garantito nel tempo.
        final persistedPath = await ImageStorageService.persistLocalImage(picked.path);
        onImagePicked(persistedPath);
      }
    } catch (e) {
      // Permesso negato, fotocamera non disponibile, utente ha annullato
      // in un modo che genera errore su alcuni dispositivi: non blocchiamo
      // l'utente, semplicemente non cambiamo l'immagine.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile accedere alla fotocamera/libreria')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: Colors.black87, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill - 1.5),
            child: _buildImage(),
          ),
        ),
        Positioned(
          bottom: -8,
          right: -8,
          child: InkWell(
            onTap: () => _showPickerSheet(context),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.black,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt, color: AppColors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    if (imagePath == null || imagePath!.isEmpty) {
      return _placeholder();
    }

    if (_isRemote) {
      return Image.network(
        imagePath!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    return Image.file(
      File(imagePath!),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Center(
      child: CircleAvatar(
        radius: size * 0.28,
        backgroundColor: AppColors.white,
        child: Icon(Icons.image, size: size * 0.28, color: AppColors.grey300),
      ),
    );
  }
}
