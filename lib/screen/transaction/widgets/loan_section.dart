import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:selavu/screen/transaction/add_transaction_screen.dart';

class LoanSection extends StatelessWidget {
  const LoanSection({
    super.key,
    required this.personController,
    required this.numberController,
    required this.principalController,
    required this.outstandingController,
    required this.noteController,
    required this.loanType,
    required this.loanStatus,
    required this.onStatusChanged,
    required this.onPickContact,
    this.contacts = const [],
  });

  final TextEditingController personController;
  final TextEditingController numberController;
  final TextEditingController principalController;
  final TextEditingController outstandingController;
  final TextEditingController noteController;
  final LoanType loanType;
  final LoanStatus loanStatus;
  final ValueChanged<LoanStatus?> onStatusChanged;
  final VoidCallback onPickContact;
  final List<Contact> contacts;

  @override
  Widget build(BuildContext context) {
    final bool isLend = loanType == LoanType.lend;
    final Color themeColor = isLend ? const Color(0xFF2E7D32) : const Color(0xFF1976D2);
    final Color bgColor = isLend ? const Color(0xFFF1F8E9) : const Color(0xFFE3F2FD);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withAlpha(30)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isLend ? Icons.arrow_upward : Icons.arrow_downward, color: themeColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      isLend ? 'Lending' : 'Borrowing',
                      style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[100],
                child: Icon(Icons.person_outline, color: themeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Autocomplete<Contact>(
                      displayStringForOption: (Contact contact) => contact.displayName ?? '',
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) return const Iterable<Contact>.empty();
                        return contacts.where((Contact contact) {
                          final name = (contact.displayName ?? '').toLowerCase();
                          final query = textEditingValue.text.toLowerCase();
                          return name.contains(query) ||
                                 contact.phones.any((p) => p.number.contains(textEditingValue.text));
                        });
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: MediaQuery.of(context).size.width - 96,
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final contact = options.elementAt(index);
                                  return ListTile(
                                    title: Text(contact.displayName ?? 'Unknown', style: const TextStyle(fontSize: 14)),
                                    subtitle: Text(
                                      contact.phones.isNotEmpty ? contact.phones.first.number : 'No number',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    onTap: () => onSelected(contact),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      onSelected: (Contact contact) {
                        personController.text = contact.displayName ?? '';
                        if (contact.phones.isNotEmpty) {
                          numberController.text = contact.phones.first.number;
                        }
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        if (controller.text != personController.text) {
                          controller.text = personController.text;
                        }
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Person Name',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: numberController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Phone Number',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        prefixIcon: Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                        prefixIconConstraints: BoxConstraints(minWidth: 20),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.contact_page_outlined, color: Colors.grey),
                onPressed: onPickContact,
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(child: _buildAmountBox('Principal', principalController, themeColor)),
              const SizedBox(width: 12),
              Expanded(child: _buildAmountBox('Outstanding', outstandingController, themeColor)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('LOAN NOTE', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextField(
            controller: noteController,
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Enter details about this loan...',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountBox(String label, TextEditingController controller, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('₹', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    String label = 'Open';
    Color color = Colors.orange;
    switch (loanStatus) {
      case LoanStatus.open: label = 'Open'; color = Colors.orange; break;
      case LoanStatus.partial: label = 'Partial'; color = Colors.blue; break;
      case LoanStatus.closed: label = 'Closed'; color = const Color(0xFF2E7D32); break;
    }

    return PopupMenuButton<LoanStatus>(
      onSelected: onStatusChanged,
      itemBuilder: (context) => [
        const PopupMenuItem(value: LoanStatus.open, child: Text('Open')),
        const PopupMenuItem(value: LoanStatus.partial, child: Text('Partial')),
        const PopupMenuItem(value: LoanStatus.closed, child: Text('Closed')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
            const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
