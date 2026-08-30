import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final bool isSelectable;
  final bool isSelected;
  final String? imageUrl;

  const ProductCard({
    super.key,
    required this.name,
    required this.onTap,
    this.onLongPress,
    this.onDelete,
    this.isSelectable = false,
    this.isSelected = false,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: onTap,
                onLongPress: onLongPress, // Utilizzato per rilevare la pressione prolungata
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.white,
                      backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
                          ? NetworkImage(imageUrl!)
                          : null,
                      onBackgroundImageError: (imageUrl != null && imageUrl!.isNotEmpty)
                          ? (_, __) {}
                          : null,
                      child: (imageUrl == null || imageUrl!.isEmpty)
                          ? Icon(Icons.image, color: Colors.black12, size: 28)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.cardTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Container(
                        width: 24,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.grey300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          if (isSelectable)
            Positioned(
              top: -8,
              right: -8,
              child: InkWell(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.black : AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: isSelected ? AppColors.white : Colors.transparent,
                  ),
                ),
              ),
            )
          else if (onDelete != null)
            Positioned(
              top: -8,
              right: -8,
              child: InkWell(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.close, size: 14, color: AppColors.grey500),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
