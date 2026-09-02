import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'main_screen.dart';
import '../providers/pantry_provider.dart';
import '../providers/location_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/house_provider.dart';
import '../services/image_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/smart_image.dart';

class HouseListScreen extends StatefulWidget {
  const HouseListScreen({super.key});

  @override
  State<HouseListScreen> createState() => _HouseListScreenState();
}

class _HouseListScreenState extends State<HouseListScreen> {
  void _showAddHouseDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => const _AddHouseDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final houses = context.watch<HouseProvider>().houses;

    return Scaffold(
      backgroundColor: AppColors.pannaWarm,
      appBar: AppBar(
        backgroundColor: AppColors.pannaWarm,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('MealBase', style: AppTextStyles.screenTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          const Text(
            'LE TUE CASE',
            style: AppTextStyles.sectionLabel,
          ),
          const SizedBox(height: 4),
          Text('Seleziona o aggiungi una casa', style: AppTextStyles.subtitle),
          const SizedBox(height: 20),
          ...houses.map(
                (house) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _HouseCard(
                name: house.nome,
                imagePath: house.imagePath,
                onTap: () async {
                  await context.read<PantryProvider>().switchHouse(house.nome);
                  await context.read<LocationProvider>().switchHouse(house.nome);
                  await context.read<ShoppingListProvider>().switchHouse(house.nome);

                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MainScreen(houseName: house.nome),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          DottedBorder(
            color: AppColors.grey300,
            strokeWidth: 1.5,
            dashPattern: const [6, 4],
            borderType: BorderType.RRect,
            radius: const Radius.circular(AppRadius.lg),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: _showAddHouseDialog,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, color: AppColors.verdeSalvia, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'AGGIUNGI UNA NUOVA CASA',
                        style: TextStyle(
                          color: AppColors.verdeBosco,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HouseCard extends StatelessWidget {
  final String name;
  final String? imagePath;
  final VoidCallback onTap;

  const _HouseCard({
    required this.name,
    this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.grey200, width: 1),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  width: 52,
                  height: 52,
                  color: AppColors.grey100,
                  child: _buildHouseImage(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.verdeBosco,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHouseImage() {
    return SmartImage(
      path: imagePath,
      fit: BoxFit.cover,
      placeholderBuilder: (_) =>
          const Icon(Icons.home_outlined, color: AppColors.verdeSalvia, size: 26),
    );
  }
}

class _AddHouseDialog extends StatefulWidget {
  const _AddHouseDialog();

  @override
  State<_AddHouseDialog> createState() => _AddHouseDialogState();
}

class _AddHouseDialogState extends State<_AddHouseDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedImagePath;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      // Come per ProductImagePicker: copiamo subito il file scelto in una
      // cartella persistente dell'app (vedi ImageStorageService) invece di
      // tenere il path temporaneo restituito da image_picker.
      final persistedPath = await ImageStorageService.persistLocalImage(pickedFile.path);
      if (!mounted) return;
      setState(() {
        _selectedImagePath = persistedPath;
      });
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.pannaWarm,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('SCEGLI IMMAGINE', style: AppTextStyles.fieldLabel),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.verdeSalvia),
                title: const Text('Galleria', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.verdeSalvia),
                title: const Text('Fotocamera', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      context.read<HouseProvider>().addHouse(name, imagePath: _selectedImagePath);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.pannaWarm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text('NUOVA CASA', style: AppTextStyles.sectionLabel),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _showImageSourcePicker,
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.grey300, width: 1.5),
                      ),
                      child: ClipOval(
                        child: _selectedImagePath != null
                            ? Image.file(
                          File(_selectedImagePath!),
                          fit: BoxFit.cover,
                        )
                            : const Icon(
                          Icons.add_a_photo_outlined,
                          size: 32,
                          color: AppColors.grey400,
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.verdeSalvia,
                        child: Icon(Icons.edit, size: 12, color: AppColors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.grey300, width: 1),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Es. Casa Mare, Montagna...',
                  hintStyle: AppTextStyles.hint,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'ANNULLA',
                      style: TextStyle(
                        color: AppColors.grey500,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.verdeSalvia,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    child: const Text(
                      'AGGIUNGI',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}