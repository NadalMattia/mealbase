import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'smart_image.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final String? brand;
  final String? imageUrl;
  final DateTime? expirationDate;
  final int? quantity;
  final bool isShoppingCard;
  final bool isSelectable;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;

  const ProductCard({
    super.key,
    required this.name,
    this.brand,
    this.imageUrl,
    this.expirationDate,
    this.quantity,
    this.isShoppingCard = false,
    this.isSelectable = false,
    this.isSelected = false,
    required this.onTap,
    this.onLongPress,
    this.onDelete,
  });

  _CardStyle _getCardStyle() {
    if (isShoppingCard) {
      return const _CardStyle(
        bgColor: AppColors.statusShoppingBg,
        borderColor: AppColors.statusShoppingBorder,
      );
    }

    if (expirationDate == null) {
      return const _CardStyle(
        bgColor: AppColors.statusNoDateBg,
        borderColor: AppColors.statusNoDateBorder,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expirationDate!.year, expirationDate!.month, expirationDate!.day);
    final daysLeft = expiry.difference(today).inDays;

    if (daysLeft <= 0) {
      return const _CardStyle(
        bgColor: AppColors.statusExpiredBg,
        borderColor: AppColors.statusExpiredBorder,
      );
    } else if (daysLeft >= 1 && daysLeft <= 3){
      return const _CardStyle(
        bgColor: AppColors.statusWarningBg,
        borderColor: AppColors.statusWarningBorder,
      );
    } else {
      return const _CardStyle(
        bgColor: AppColors.statusFreshBg,
        borderColor: AppColors.statusFreshBorder,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardStyle = _getCardStyle();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isSelected ? AppColors.black : cardStyle.borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg - 1)),
                    child: _buildImage(),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: cardStyle.bgColor,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.lg - 1)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.cardTitle,
                      ),
                      if (brand != null && brand!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          brand!.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // FIX: il badge "xN" della quantità DEVE essere figlio diretto
          // dello Stack esterno. Prima era annidato dentro due Column
          // (quello dell'immagine+info, e quello del testo nome/marca):
          // Positioned funziona solo se il suo genitore immediato è uno
          // Stack, quindi in quella posizione Flutter lanciava un errore
          // di layout ("Incorrect use of ParentDataWidget") ogni volta
          // che un prodotto aveva quantity > 1 — la card si rompeva del
          // tutto (il rettangolo grigio senza contenuto negli screenshot),
          // mostrando solo il pulsante di chiusura, che essendo un altro
          // Positioned diretto dello Stack continuava a renderizzare
          // correttamente.
          if (quantity != null && quantity! > 1)
            Positioned(
              bottom: 46,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.white, width: 1),
                ),
                child: Text(
                  'x$quantity',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (isSelectable)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.black : AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.grey300),
                ),
                child: Icon(
                  isSelected ? Icons.check : Icons.circle_outlined,
                  size: 16,
                  color: isSelected ? AppColors.white : AppColors.grey400,
                ),
              ),
            )
          else if (onDelete != null)
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: AppColors.black),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return SmartImage(
      path: imageUrl,
      fit: BoxFit.cover,
      placeholderBuilder: (_) => Container(
        color: AppColors.white.withValues(alpha: 0.5),
        child: const Icon(Icons.image, color: AppColors.grey400, size: 32),
      ),
      errorBuilder: (_) => Container(
        color: AppColors.white.withValues(alpha: 0.5),
        child: const Icon(Icons.broken_image, color: AppColors.grey400, size: 24),
      ),
    );
  }
}

class _CardStyle {
  final Color bgColor;
  final Color borderColor;

  const _CardStyle({
    required this.bgColor,
    required this.borderColor,
  });
}