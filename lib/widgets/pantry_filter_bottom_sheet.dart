import 'package:flutter/material.dart';
import '../models/pantry_sort_option.dart';
import '../models/product_category.dart';
import '../theme/app_theme.dart';

class PantryFilterBottomSheet extends StatefulWidget {
  final PantrySortOption currentSort;
  final String? currentCategory;
  final Function(PantrySortOption sort, String? category) onApply;

  const PantryFilterBottomSheet({
    super.key,
    required this.currentSort,
    required this.currentCategory,
    required this.onApply,
  });

  @override
  State<PantryFilterBottomSheet> createState() => _PantryFilterBottomSheetState();
}

class _PantryFilterBottomSheetState extends State<PantryFilterBottomSheet> {
  late PantrySortOption _selectedSort;
  late String? _selectedCategory;

  // 'Tutte' è un valore "sentinella" solo per la UI del filtro (nessun
  // prodotto ha davvero categoria 'Tutte'), quindi resta una stringa a sé
  // e non fa parte dell'enum ProductCategory. Le categorie vere vengono
  // da ProductCategories.labels: prima questa lista era hardcoded qui e
  // duplicata identicamente in product_form_screen.dart, con il rischio
  // che le due si disallineassero nel tempo.
  final List<String> _categories = ['Tutte', ...ProductCategories.labels];

  @override
  void initState() {
    super.initState();
    _selectedSort = widget.currentSort;
    _selectedCategory = widget.currentCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.pill)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('FILTRA & ORDINA', style: AppTextStyles.sectionLabel),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedSort = PantrySortOption.insertionDesc;
                    _selectedCategory = null;
                  });
                },
                child: const Text(
                  'RIPRISTINA',
                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('ORDINAMENTO', style: AppTextStyles.fieldLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSortChip('In scadenza prima', PantrySortOption.expirationAsc),
              _buildSortChip('Più recenti', PantrySortOption.insertionDesc),
              _buildSortChip('Meno recenti', PantrySortOption.insertionAsc),
              _buildSortChip('Per Categoria', PantrySortOption.category),
            ],
          ),
          const SizedBox(height: 24),
          const Text('FILTRA PER CATEGORIA', style: AppTextStyles.fieldLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = (_selectedCategory == null && cat == 'Tutte') || _selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                selectedColor: AppColors.black,
                backgroundColor: AppColors.grey100,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                showCheckmark: false,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = (cat == 'Tutte' || !selected) ? null : cat;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          InkWell(
            onTap: () {
              widget.onApply(_selectedSort, _selectedCategory);
              Navigator.pop(context);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              alignment: Alignment.center,
              child: const Text('MOSTRA RISULTATI', style: AppTextStyles.pillButtonLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, PantrySortOption option) {
    final isSelected = _selectedSort == option;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.black,
      backgroundColor: AppColors.grey100,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.white : AppColors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      showCheckmark: false,
      onSelected: (selected) {
        if (selected) setState(() => _selectedSort = option);
      },
    );
  }
}