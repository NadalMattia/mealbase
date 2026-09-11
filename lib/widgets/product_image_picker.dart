import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/image_storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import 'smart_image.dart';


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
      if (picked == null) return;

      // Copiamo subito il file in una cartella persistente dell'app
      // (vedi ImageStorageService per i dettagli sul "perché") invece di
      // tenere il path temporaneo restituito da image_picker, che su
      // alcune piattaforme non è garantito nel tempo.
      final persistedPath = await ImageStorageService.persistLocalImage(picked.path);

      // Scattare una foto può richiedere molto tempo: lo schermo potrebbe
      // essere stato chiuso nel frattempo, e `onImagePicked` porta a un
      // setState nel chiamante.
      if (!context.mounted) return;
      onImagePicked(persistedPath);
    } catch (e) {
      if (!context.mounted) return;
      await _showAccessError(context, source);
    }
  }

  /// Segnala l'impossibilità di accedere a fotocamera o galleria.
  ///
  /// Per la fotocamera, un permesso negato in modo permanente merita un
  /// messaggio diverso: ritentare non produrrà mai nulla, perché il
  /// sistema non mostra più la richiesta. In quel caso si offre la
  /// scorciatoia alle impostazioni, come già fa [ScannerPermissionDenied]
  /// per lo scanner.
  ///
  /// Per la galleria si mostra sempre il messaggio generico: su Android
  /// recenti `image_picker` usa il selettore di sistema, che non richiede
  /// alcun permesso, quindi interrogare `Permission.photos` - non
  /// dichiarato nel manifest - riporterebbe un diniego inesistente.
  Future<void> _showAccessError(BuildContext context, ImageSource source) async {
    if (source == ImageSource.gallery) {
      AppSnackbar.show(
        context,
        message: 'Impossibile accedere alla galleria',
        icon: Icons.error_outline,
      );
      return;
    }

    // La verifica può fallire su piattaforme che non espongono il
    // permesso: in quel caso si ripiega sul messaggio generico.
    var isPermanentlyDenied = false;
    try {
      isPermanentlyDenied = await Permission.camera.isPermanentlyDenied;
    } catch (_) {
      isPermanentlyDenied = false;
    }

    if (!context.mounted) return;

    if (!isPermanentlyDenied) {
      AppSnackbar.show(
        context,
        message: 'Impossibile accedere alla fotocamera',
        icon: Icons.error_outline,
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Permesso negato'),
        content: const Text(
          'Per scattare una foto del prodotto serve il permesso di accesso '
          'alla fotocamera, che risulta negato. Puoi concederlo dalle '
          'impostazioni di sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              openAppSettings();
            },
            child: const Text('IMPOSTAZIONI'),
          ),
        ],
      ),
    );
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
                    color: Colors.black.withValues(alpha: 0.15),
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
    return SmartImage(
      path: imagePath,
      fit: BoxFit.cover,
      showNetworkLoadingIndicator: true,
      placeholderBuilder: (_) => _placeholder(),
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
