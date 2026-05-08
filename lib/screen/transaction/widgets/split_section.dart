import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:selavu/screen/transaction/add_transaction_screen.dart';

class SplitSection extends StatelessWidget {
  const SplitSection({
    super.key,
    required this.splitMode,
    required this.includeMeInSplit,
    required this.mySplitAmountController,
    required this.splitItems,
    required this.onModeChanged,
    required this.onIncludeMeChanged,
    required this.onAddPerson,
    required this.onRemovePerson,
    required this.onPickContact,
    required this.onSettledChanged,
    this.contacts = const [],
  });

  final SplitMode splitMode;
  final bool includeMeInSplit;
  final TextEditingController mySplitAmountController;
  final List<SplitItemController> splitItems;
  final ValueChanged<SplitMode?> onModeChanged;
  final ValueChanged<bool?> onIncludeMeChanged;
  final VoidCallback onAddPerson;
  final ValueChanged<int> onRemovePerson;
  final Function(TextEditingController, TextEditingController) onPickContact;
  final Function(int, bool) onSettledChanged;
  final List<Contact> contacts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _CustomSwitch(
              label: 'Equal split',
              value: splitMode == SplitMode.equal,
              onChanged: (val) => onModeChanged(val ? SplitMode.equal : SplitMode.exact),
            ),
            const SizedBox(width: 16),
            _CustomSwitch(
              label: 'Include me',
              value: includeMeInSplit,
              onChanged: onIncludeMeChanged,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'People in split:',
              style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 16),
            ),
            InkWell(
              onTap: onAddPerson,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Color(0xFF2E7D32), size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Add person',
                      style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...splitItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _PersonSplitRow(
            item: item,
            contacts: contacts,
            splitMode: splitMode,
            onPickContact: () => onPickContact(item.nameController, item.numberController),
            onRemove: () => onRemovePerson(index),
            onSettledChanged: (val) => onSettledChanged(index, val),
          );
        }),
      ],
    );
  }
}

class _CustomSwitch extends StatelessWidget {
  const _CustomSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          SizedBox(
            height: 20,
            width: 36,
            child: FittedBox(
              fit: BoxFit.fill,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonSplitRow extends StatelessWidget {
  const _PersonSplitRow({
    required this.item,
    required this.contacts,
    required this.splitMode,
    required this.onPickContact,
    required this.onRemove,
    required this.onSettledChanged,
  });

  final SplitItemController item;
  final List<Contact> contacts;
  final SplitMode splitMode;
  final VoidCallback onPickContact;
  final VoidCallback onRemove;
  final ValueChanged<bool> onSettledChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF1F8E9),
                child: const Icon(Icons.person, color: Color(0xFF2E7D32), size: 20),
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
                              width: MediaQuery.of(context).size.width - 64,
                              constraints: const BoxConstraints(maxHeight: 250),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final contact = options.elementAt(index);
                                  final String name = contact.displayName ?? 'Unknown';
                                  return ListTile(
                                    leading: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.grey[200],
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(name, style: const TextStyle(fontSize: 14)),
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
                        item.nameController.text = contact.displayName ?? '';
                        if (contact.phones.isNotEmpty) {
                          item.numberController.text = contact.phones.first.number;
                        }
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        if (controller.text != item.nameController.text) {
                          controller.text = item.nameController.text;
                        }
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Name',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: item.numberController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: 'Phone number',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 90,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('AMOUNT', style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('₹', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: item.amountController,
                            textAlign: TextAlign.right,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            readOnly: splitMode == SplitMode.equal,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              InkWell(
                onTap: () => onSettledChanged(!item.settled),
                child: Row(
                  children: [
                    Icon(
                      item.settled ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: item.settled ? const Color(0xFF2E7D32) : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SETTLED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: item.settled ? const Color(0xFF2E7D32) : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
