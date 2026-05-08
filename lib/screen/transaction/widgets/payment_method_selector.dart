import 'package:flutter/material.dart';
import 'package:selavu/core/data/transaction_repository.dart';
import 'package:selavu/core/util/ui_util.dart';

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.paymentMethods,
    required this.selectedPaymentMethodId,
    required this.onPaymentMethodSelected,
    this.onAddPaymentMethod,
  });

  final List<PaymentMethod> paymentMethods;
  final int? selectedPaymentMethodId;
  final ValueChanged<PaymentMethod> onPaymentMethodSelected;
  final VoidCallback? onAddPaymentMethod;

  PaymentMethod? get _selectedMethod {
    if (selectedPaymentMethodId == null) return null;
    try {
      return paymentMethods.firstWhere((m) => m.id == selectedPaymentMethodId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedMethod;
    final Color color = UIUtil.hexToColor(selected?.color);

    return Container(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showPaymentMethodPicker(context),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                UIUtil.getIconData(selected?.icon, defaultIcon: Icons.account_balance_wallet),
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              selected?.name ?? 'Payment Method',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _showPaymentMethodPicker(BuildContext context) async {
    if (paymentMethods.isEmpty) return;

    final PaymentMethod? selected = await showModalBottomSheet<PaymentMethod>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.pushNamed(context, '/manage-payment-methods');
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: paymentMethods
                      .map(
                        (PaymentMethod method) {
                          final Color methodColor = UIUtil.hexToColor(method.color);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: methodColor.withOpacity(0.15),
                              child: Icon(
                                UIUtil.getIconData(method.icon, defaultIcon: Icons.account_balance_wallet),
                                color: methodColor,
                                size: 20,
                              ),
                            ),
                            title: Text(method.name),
                            onTap: () => Navigator.of(sheetContext).pop(method),
                          );
                        },
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      onPaymentMethodSelected(selected);
    }
  }
}
