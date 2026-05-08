import 'package:flutter/material.dart';
import 'package:selavu/core/data/transaction_repository.dart';
import 'package:selavu/core/service/transaction_service.dart';
import 'package:selavu/core/util/ui_util.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final TransactionService _service = TransactionService();
  List<Category> _categories = <Category>[];
  bool _isLoading = true;

  final List<String> _colors = [
    '#F44336', '#E91E63', '#9C27B0', '#673AB7', '#3F51B5', '#2196F3', '#03A9F4', '#00BCD4',
    '#009688', '#4CAF50', '#8BC34A', '#CDDC39', '#FFEB3B', '#FFC107', '#FF9800', '#FF5722',
    '#795548', '#9E9E9E', '#607D8B'
  ];

  final List<String> _icons = [
    'category', 'shopping_cart', 'restaurant', 'directions_car', 'home', 'flight', 
    'local_movies', 'fitness_center', 'school', 'medical_services', 'payments', 
    'account_balance', 'savings', 'build', 'electric_bolt', 'water_drop', 'pets', 
    'local_shipping', 'work', 'card_giftcard'
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final cats = await _service.getAllCategories();
    setState(() {
      _categories = cats;
      _isLoading = false;
    });
  }

  void _showAddEditDialog([Category? category]) {
    final nameController = TextEditingController(text: category?.name ?? '');
    String type = category?.type ?? 'expense';
    String icon = category?.icon ?? 'category';
    String color = category?.color ?? '#4CAF50';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 10,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category == null ? 'Add Category' : 'Edit Category',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _typeChip('expense', type, (val) => setSheetState(() => type = val)),
                    const SizedBox(width: 8),
                    _typeChip('income', type, (val) => setSheetState(() => type = val)),
                    const SizedBox(width: 8),
                    _typeChip('both', type, (val) => setSheetState(() => type = val)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Icon', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _icons.length,
                    itemBuilder: (context, index) {
                      final i = _icons[index];
                      final bool isSelected = i == icon;
                      return GestureDetector(
                        onTap: () => setSheetState(() => icon = i),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? UIUtil.hexToColor(color).withAlpha(40) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected ? Border.all(color: UIUtil.hexToColor(color), width: 2) : null,
                          ),
                          child: Icon(UIUtil.getIconData(i), color: isSelected ? UIUtil.hexToColor(color) : Colors.grey[600], size: 24),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colors.length,
                    itemBuilder: (context, index) {
                      final c = _colors[index];
                      final bool isSelected = c == color;
                      final Color col = UIUtil.hexToColor(c);
                      return GestureDetector(
                        onTap: () => setSheetState(() => color = c),
                        child: Container(
                          width: 40,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                            boxShadow: [
                              if (isSelected) BoxShadow(color: col.withAlpha(100), blurRadius: 8, spreadRadius: 2)
                            ],
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;
                      if (category == null) {
                        await _service.addCategory(
                          name: nameController.text.trim(),
                          type: type,
                          icon: icon,
                          color: color,
                        );
                      } else {
                        await _service.updateCategory(
                          id: category.id,
                          name: nameController.text.trim(),
                          type: type,
                          icon: icon,
                          color: color,
                        );
                      }
                      if (!mounted) return;
                      Navigator.pop(context);
                      _loadCategories();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: const Color(0xFF1B5E20),
                    ),
                    child: Text(category == null ? 'Add Category' : 'Save Changes'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String label, String current, Function(String) onSelect) {
    final bool isSelected = label == current;
    return ChoiceChip(
      label: Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      selected: isSelected,
      onSelected: (_) => onSelect(label),
      selectedColor: const Color(0xFF1B5E20).withAlpha(40),
      labelStyle: TextStyle(color: isSelected ? const Color(0xFF1B5E20) : Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Manage Categories', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final color = UIUtil.hexToColor(cat.color);
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.withAlpha(40)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(UIUtil.getIconData(cat.icon), color: color, size: 24),
                    ),
                    title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(cat.type.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 22, color: Colors.blueGrey),
                          onPressed: () => _showAddEditDialog(cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 22, color: Colors.redAccent),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Category'),
                                content: const Text('Are you sure? This will not delete transactions using this category but they will lose their styling.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('DELETE'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && mounted) {
                              await _service.deleteCategory(cat.id);
                              _loadCategories();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        label: const Text('Add Category', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
    );
  }
}
