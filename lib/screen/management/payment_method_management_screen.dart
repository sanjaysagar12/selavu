import 'package:flutter/material.dart';
import 'package:selavu/core/data/transaction_repository.dart';
import 'package:selavu/core/service/transaction_service.dart';
import 'package:selavu/core/util/ui_util.dart';

class PaymentMethodManagementScreen extends StatefulWidget {
  const PaymentMethodManagementScreen({super.key});

  @override
  State<PaymentMethodManagementScreen> createState() => _PaymentMethodManagementScreenState();
}

class _PaymentMethodManagementScreenState extends State<PaymentMethodManagementScreen> {
  final TransactionService _service = TransactionService();
  List<PaymentMethod> _methods = <PaymentMethod>[];
  bool _isLoading = true;

  final List<String> _colors = [
    '#2196F3', '#1976D2', '#0D47A1', '#00BCD4', '#009688', '#4CAF50', '#2E7D32', '#673AB7',
    '#9C27B0', '#E91E63', '#F44336', '#FF9800', '#FF5722', '#795548', '#607D8B'
  ];

  final List<String> _icons = [
    'account_balance_wallet', 'account_balance', 'credit_card', 'payments', 
    'savings', 'currency_rupee', 'qr_code', 'smartphone', 'store', 'person', 
    'business', 'star', 'home', 'work'
  ];

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    setState(() => _isLoading = true);
    final methods = await _service.getPaymentMethods();
    setState(() {
      _methods = methods;
      _isLoading = false;
    });
  }

  void _showAddEditDialog([PaymentMethod? method]) {
    final nameController = TextEditingController(text: method?.name ?? '');
    String icon = method?.icon ?? 'account_balance_wallet';
    String color = method?.color ?? '#1976D2';

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
                  method == null ? 'Add Payment Method' : 'Edit Payment Method',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g. HDFC Bank, PayTM, Cash',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
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
                          child: Icon(UIUtil.getIconData(i, defaultIcon: Icons.account_balance_wallet), color: isSelected ? UIUtil.hexToColor(color) : Colors.grey[600], size: 24),
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
                      if (method == null) {
                        await _service.addPaymentMethodWithDetails(
                          name: nameController.text.trim(),
                          icon: icon,
                          color: color,
                        );
                      } else {
                        await _service.updatePaymentMethod(
                          id: method.id,
                          name: nameController.text.trim(),
                          icon: icon,
                          color: color,
                        );
                      }
                      if (!mounted) return;
                      Navigator.pop(context);
                      _loadMethods();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: const Color(0xFF1B5E20),
                    ),
                    child: Text(method == null ? 'Add Method' : 'Save Changes'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Manage Payment Methods', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () => _showAddEditDialog(),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Method',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _methods.length,
              itemBuilder: (context, index) {
                final method = _methods[index];
                final color = UIUtil.hexToColor(method.color);
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
                      child: Icon(UIUtil.getIconData(method.icon, defaultIcon: Icons.account_balance_wallet), color: color, size: 24),
                    ),
                    title: Text(method.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 22, color: Colors.blueGrey),
                          onPressed: () => _showAddEditDialog(method),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 22, color: Colors.redAccent),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Method'),
                                content: const Text('Are you sure? Transactions using this method will lose their styling.'),
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
                              await _service.deletePaymentMethod(method.id);
                              _loadMethods();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
