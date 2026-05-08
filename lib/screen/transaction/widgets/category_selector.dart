import 'package:flutter/material.dart';
import 'package:selavu/core/data/transaction_repository.dart';
import 'package:selavu/core/util/ui_util.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  final List<Category> categories;
  final int? selectedCategoryId;
  final ValueChanged<Category> onCategorySelected;

  Category? get _selectedCategory {
    if (selectedCategoryId == null) return null;
    try {
      return categories.firstWhere((c) => c.id == selectedCategoryId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedCategory;
    final Color color = UIUtil.hexToColor(selected?.color);

    return Container(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showCategoryPicker(context),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                UIUtil.getIconData(selected?.icon),
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              selected?.name ?? 'Category',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _showCategoryPicker(BuildContext context) async {
    if (categories.isEmpty) return;

    final Category? selected = await showModalBottomSheet<Category>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: ListView(
            children: categories
                .map(
                  (Category category) {
                    final Color catColor = UIUtil.hexToColor(category.color);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: catColor.withOpacity(0.15),
                        child: Icon(
                          UIUtil.getIconData(category.icon),
                          color: catColor,
                          size: 20,
                        ),
                      ),
                      title: Text(category.name),
                      onTap: () => Navigator.of(sheetContext).pop(category),
                    );
                  },
                )
                .toList(growable: false),
          ),
        );
      },
    );

    if (selected != null) {
      onCategorySelected(selected);
    }
  }
}
