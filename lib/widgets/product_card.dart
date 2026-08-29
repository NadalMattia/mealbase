import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isSelectable;
  final bool isSelected;

  const ProductCard({
    super.key,
    required this.name,
    required this.onTap,
    this.onDelete,
    this.isSelectable = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Spazio "invisibile" esterno per far uscire la spunta senza essere tagliata
      padding: const EdgeInsets.only(top: 8, right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. La card base che riempie lo spazio disponibile
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.image, color: Colors.black12, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
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
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          // 2. Modalità Selezione Multipla (Checkbox)
          if (isSelectable)
            Positioned(
              top: -8, // Sale in negativo per sormontare il bordo alto
              right: -8, // Esce in negativo per sormontare il bordo destro
              child: InkWell(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.white,
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
                    color: isSelected ? Colors.white : Colors.transparent,
                  ),
                ),
              ),
            )
          // 3. Modalità Normale (X per eliminazione singola)
          else if (onDelete != null)
            Positioned(
              top: -8,
              right: -8,
              child: InkWell(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                  child: const Icon(Icons.close, size: 14, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}