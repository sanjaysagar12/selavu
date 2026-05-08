import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import 'package:selavu/core/data/transaction_repository.dart';
import 'package:selavu/core/model/sms_payload.dart';
import 'package:selavu/core/service/transaction_service.dart';
import 'package:selavu/core/util/sms_hash.dart';
import 'package:selavu/core/util/sms_parser.dart';

import 'package:selavu/screen/transaction/widgets/category_selector.dart';
import 'package:selavu/screen/transaction/widgets/loan_section.dart';
import 'package:selavu/screen/transaction/widgets/payment_method_selector.dart';
import 'package:selavu/screen/transaction/widgets/sms_details_card.dart';
import 'package:selavu/screen/transaction/widgets/split_section.dart';
import 'package:selavu/screen/transaction/widgets/type_selectors.dart';

enum TransactionType { expense, income }

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.smsPayload,
    this.initialAmount,
    this.initialCounterparty,
    this.initialType = TransactionType.expense,
  });

  final SmsPayload? smsPayload;
  final double? initialAmount;
  final String? initialCounterparty;
  final TransactionType initialType;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TransactionService _service = TransactionService();
  late TransactionType _type;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _counterpartyController = TextEditingController();

  final TextEditingController _loanPersonController = TextEditingController();
  final TextEditingController _loanNumberController = TextEditingController();
  final TextEditingController _loanPrincipalController =
      TextEditingController();
  final TextEditingController _loanOutstandingController =
      TextEditingController();
  final TextEditingController _loanNoteController = TextEditingController();
  final TextEditingController _mySplitAmountController =
      TextEditingController();

  List<Category> _categories = <Category>[];
  List<PaymentMethod> _paymentMethods = <PaymentMethod>[];

  int? _selectedCategoryId;
  int? _selectedPaymentMethodId;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  ExtraType _extraType = ExtraType.none;
  SplitMode _splitMode = SplitMode.equal;
  bool _includeMeInSplit = true;
  final List<SplitItemController> _splitItems = <SplitItemController>[];

  LoanType _loanType = LoanType.lend;
  LoanStatus _loanStatus = LoanStatus.open;
  List<Contact> _allContacts = <Contact>[];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _loadLookups();
    _prefillData();
    _addSplitItem();
    _fetchContacts();
    _amountController.addListener(_updateEqualSplitAmounts);
  }

  Future<void> _fetchContacts() async {
    try {
      final ph.PermissionStatus status = await ph.Permission.contacts.status;
      if (status == ph.PermissionStatus.granted) {
        final List<Contact> contacts = await FlutterContacts.getAll(
          properties: {ContactProperty.phone},
        );
        setState(() {
          _allContacts = contacts;
        });
      }
    } catch (_) {}
  }

  void _updateEqualSplitAmounts() {
    if (_extraType != ExtraType.split || _splitMode != SplitMode.equal) return;

    final double? totalAmount = double.tryParse(_amountController.text.trim());
    if (totalAmount == null) return;

    final int participantCount = _splitItems.length + (_includeMeInSplit ? 1 : 0);
    if (participantCount == 0) return;

    final double share = totalAmount / participantCount;
    final String shareStr = share.toStringAsFixed(2);

    for (final SplitItemController item in _splitItems) {
      if (item.amountController.text != shareStr) {
        item.amountController.text = shareStr;
      }
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateEqualSplitAmounts);
    _amountController.dispose();
    _noteController.dispose();
    _counterpartyController.dispose();
    _loanPersonController.dispose();
    _loanNumberController.dispose();
    _loanPrincipalController.dispose();
    _loanOutstandingController.dispose();
    _loanNoteController.dispose();
    _mySplitAmountController.dispose();
    for (final SplitItemController item in _splitItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadLookups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<Category> categories =
          _type == TransactionType.expense
              ? await _service.getExpenseCategories()
              : await _service.getIncomeCategories();
      final List<PaymentMethod> methods = await _service.getPaymentMethods();

      int? selectedMethodId = _selectedPaymentMethodId;
      if (widget.smsPayload != null && selectedMethodId == null) {
        final PaymentMethod upi = methods.firstWhere(
          (PaymentMethod method) => method.name.toLowerCase() == 'upi',
          orElse: () => const PaymentMethod(id: -1, name: ''),
        );
        if (upi.id != -1) {
          selectedMethodId = upi.id;
        }
      }

      setState(() {
        _categories = categories;
        _paymentMethods = methods;
        _selectedPaymentMethodId = selectedMethodId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _prefillData() {
    final double? initAmount = widget.initialAmount;
    if (initAmount != null) {
      _amountController.text = initAmount.toStringAsFixed(2);
    } else if (widget.smsPayload != null) {
      final double? smsAmount = SmsParser.extractAmount(widget.smsPayload!.body);
      if (smsAmount != null) {
        _amountController.text = smsAmount.toStringAsFixed(2);
      }
    }

    final String? initCounterparty = widget.initialCounterparty;
    if (initCounterparty != null && initCounterparty.isNotEmpty) {
      _counterpartyController.text = initCounterparty;
    } else if (widget.smsPayload != null) {
      _counterpartyController.text = widget.smsPayload!.sender;
    }
  }

  void _addSplitItem() {
    setState(() {
      _splitItems.add(SplitItemController());
    });
    _updateEqualSplitAmounts();
  }

  void _removeSplitItem(int index) {
    setState(() {
      final SplitItemController item = _splitItems.removeAt(index);
      item.dispose();
    });
    _updateEqualSplitAmounts();
  }

  Future<void> _promptAddPaymentMethod() async {
    final TextEditingController controller = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add Payment Method'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      controller.dispose();
      return;
    }

    final String name = controller.text.trim();
    controller.dispose();
    if (name.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a payment method name.')),
      );
      return;
    }

    try {
      final int newId = await _service.addPaymentMethod(name);
      final List<PaymentMethod> methods = await _service.getPaymentMethods();
      if (!context.mounted) return;
      setState(() {
        _paymentMethods = methods;
        _selectedPaymentMethodId = newId;
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add method: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveTransaction() async {
    final double? amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount.')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a category.')),
      );
      return;
    }

    if (_selectedPaymentMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a payment method.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final SmsPayload? sms = widget.smsPayload;
      final String? smsHash = sms == null
          ? null
          : computeSmsHash(
              sender: sms.sender,
              body: sms.body,
              receivedAt: sms.receivedAt,
            );

      if (_type == TransactionType.income) {
        await _service.addIncomeWithDetails(
          amount: amount,
          categoryId: _selectedCategoryId,
          paymentMethodId: _selectedPaymentMethodId,
          counterparty: _counterpartyController.text.trim().isEmpty
              ? null
              : _counterpartyController.text.trim(),
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          smsHash: smsHash,
          smsSender: sms?.sender,
          smsBody: sms?.body,
          smsReceivedAt: sms?.receivedAt,
        );
      } else {
        SplitTransactionInput? splitInput;
        LoanTransactionInput? loanInput;

        if (_extraType == ExtraType.split) {
          final List<SplitItemInput> items = _buildSplitItems(amount);
          if (items.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add at least one split item.')),
            );
            return;
          }
          splitInput = SplitTransactionInput(
            mode: _splitMode == SplitMode.equal ? 'equal' : 'exact',
            totalAmount: amount,
            items: items,
          );
        } else if (_extraType == ExtraType.loan) {
          final String personName = _loanPersonController.text.trim();
          final double? principal =
              double.tryParse(_loanPrincipalController.text.trim());
          final double? outstanding =
              double.tryParse(_loanOutstandingController.text.trim());

          if (personName.isEmpty || principal == null || outstanding == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fill all loan details.')),
            );
            return;
          }

          loanInput = LoanTransactionInput(
            personName: personName,
            personNumber: _loanNumberController.text.trim().isEmpty
                ? null
                : _loanNumberController.text.trim(),
            loanType: _loanType == LoanType.lend ? 'lend' : 'borrow',
            principalAmount: principal,
            outstandingAmount: outstanding,
            status: _loanStatus.name,
            note: _loanNoteController.text.trim().isEmpty
                ? null
                : _loanNoteController.text.trim(),
          );
        }

        await _service.addExpenseWithExtras(
          amount: amount,
          categoryId: _selectedCategoryId,
          paymentMethodId: _selectedPaymentMethodId,
          counterparty: _counterpartyController.text.trim().isEmpty
              ? null
              : _counterpartyController.text.trim(),
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          smsHash: smsHash,
          smsSender: sms?.sender,
          smsBody: sms?.body,
          smsReceivedAt: sms?.receivedAt,
          split: splitInput,
          loan: loanInput,
        );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_type.name} saved.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  List<SplitItemInput> _buildSplitItems(double totalAmount) {
    final List<SplitItemInput> items = <SplitItemInput>[];
    final List<SplitItemController> namedItems = _splitItems
        .where((item) => item.nameController.text.trim().isNotEmpty)
        .toList(growable: false);
    final int participantCount = namedItems.length + (_includeMeInSplit ? 1 : 0);

    if (participantCount == 0) return items;

    final double equalShare = totalAmount / participantCount;

    for (final SplitItemController item in namedItems) {
      double amount = 0;
      final double? parsed = double.tryParse(item.amountController.text.trim());
      if (_splitMode == SplitMode.equal) {
        amount = equalShare;
      } else if (parsed != null && parsed >= 0) {
        amount = parsed;
      }

      items.add(
        SplitItemInput(
          personName: item.nameController.text.trim(),
          personNumber: item.numberController.text.trim().isEmpty
              ? null
              : item.numberController.text.trim(),
          amount: amount,
          settled: item.settled,
        ),
      );
    }

    if (_includeMeInSplit) {
      final double? myExactAmount =
          double.tryParse(_mySplitAmountController.text.trim());
      items.add(
        SplitItemInput(
          personName: 'Me',
          personNumber: null,
          amount: _splitMode == SplitMode.equal
              ? equalShare
              : ((myExactAmount != null && myExactAmount >= 0)
                  ? myExactAmount
                  : 0),
          settled: true,
        ),
      );
    }

    return items;
  }

  Future<void> _pickContact({
    required TextEditingController nameController,
    required TextEditingController numberController,
  }) async {
    try {
      final ph.PermissionStatus status = await ph.Permission.contacts.request();
      if (status != ph.PermissionStatus.granted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission is required.')),
        );
        return;
      }

      final String? contactId = await FlutterContacts.native.showPicker();
      if (contactId == null) return;

      final Contact? fullContact =
          await FlutterContacts.get(contactId, properties: ContactProperties.all);
      if (fullContact == null) return;

      setState(() {
        nameController.text = fullContact.displayName ?? 'Unknown';
        if (fullContact.phones.isNotEmpty) {
          numberController.text = fullContact.phones.first.number;
        }
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick contact: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add a transaction',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildForm(context),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_error ?? 'Failed to load data.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadLookups,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final SmsPayload? sms = widget.smsPayload;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: <Widget>[
        TransactionTypeSelector(
          selectedType: _type,
          onTypeChanged: (type) {
            setState(() {
              _type = type;
              _selectedCategoryId = null;
              if (_type == TransactionType.income) {
                _loanType = LoanType.borrow;
                if (_extraType == ExtraType.split) _extraType = ExtraType.none;
              } else {
                _loanType = LoanType.lend;
              }
            });
            _loadLookups();
          },
        ),
        const SizedBox(height: 8),
        // Amount Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withAlpha(40)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                _type == TransactionType.expense ? 'Amount spent' : 'Amount received',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '₹',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  IntrinsicWidth(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.north_east, color: Colors.grey[400], size: 20),
                ],
              ),
              const Divider(thickness: 1, height: 24),
              // Unified Details Rows
              _buildDetailRow(
                label: 'Date & time',
                value: 'Today, ${TimeOfDay.now().format(context)}',
                onTap: () {}, // Date picker
              ),
              const Divider(height: 1),
              _buildDetailRow(
                label: _type == TransactionType.expense ? 'Paid to' : 'Received from',
                isInput: true,
                controller: _counterpartyController,
                hint: 'Enter the name or place',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Payment Method Selector
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withAlpha(40)),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: PaymentMethodSelector(
            paymentMethods: _paymentMethods,
            selectedPaymentMethodId: _selectedPaymentMethodId,
            onPaymentMethodSelected: (m) =>
                setState(() => _selectedPaymentMethodId = m.id),
            onAddPaymentMethod: _promptAddPaymentMethod,
            onRefresh: _loadLookups,
          ),
        ),
        const SizedBox(height: 16),
        // Category Selector
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withAlpha(40)),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: CategorySelector(
            categories: _categories,
            selectedCategoryId: _selectedCategoryId,
            onCategorySelected: (cat) =>
                setState(() => _selectedCategoryId = cat.id),
            onRefresh: _loadLookups,
          ),
        ),
        const SizedBox(height: 16),
        // Extras Section
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withAlpha(40)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              ExtraTypeSelector(
                transactionType: _type,
                selectedExtraType: _extraType,
                onExtraTypeChanged: (type) {
                  setState(() {
                    _extraType = type;
                    if (_extraType == ExtraType.loan) {
                      _loanType = _type == TransactionType.income
                          ? LoanType.borrow
                          : LoanType.lend;
                    }
                  });
                },
              ),
              if (_extraType != ExtraType.none) const SizedBox(height: 12),
              if (_extraType == ExtraType.split && _type == TransactionType.expense)
                SplitSection(
                  splitMode: _splitMode,
                  includeMeInSplit: _includeMeInSplit,
                  mySplitAmountController: _mySplitAmountController,
                  splitItems: _splitItems,
                  contacts: _allContacts,
                  onModeChanged: (val) {
                    setState(() => _splitMode = val!);
                    _updateEqualSplitAmounts();
                  },
                  onIncludeMeChanged: (val) {
                    setState(() => _includeMeInSplit = val!);
                    _updateEqualSplitAmounts();
                  },
                  onAddPerson: _addSplitItem,
                  onRemovePerson: _removeSplitItem,
                  onPickContact: (name, number) =>
                      _pickContact(nameController: name, numberController: number),
                  onSettledChanged: (idx, val) =>
                      setState(() => _splitItems[idx].settled = val),
                )
              else if (_extraType == ExtraType.loan)
                LoanSection(
                  personController: _loanPersonController,
                  numberController: _loanNumberController,
                  principalController: _loanPrincipalController,
                  outstandingController: _loanOutstandingController,
                  noteController: _loanNoteController,
                  loanType: _loanType,
                  loanStatus: _loanStatus,
                  contacts: _allContacts,
                  onStatusChanged: (val) => setState(() => _loanStatus = val!),
                  onPickContact: () => _pickContact(
                    nameController: _loanPersonController,
                    numberController: _loanNumberController,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _isSaving ? null : _saveTransaction,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text('Save ${_type.name}', style: const TextStyle(fontSize: 16)),
        ),
        if (sms != null) ...[
          const SizedBox(height: 12),
          SmsDetailsCard(sms: sms),
        ],
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildDetailRow({
    required String label,
    String? value,
    bool isInput = false,
    TextEditingController? controller,
    String? hint,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                label,
                style: const TextStyle(color: Colors.black, fontSize: 15),
              ),
            ),
            Expanded(
              flex: 6,
              child: isInput
                  ? TextField(
                      controller: controller,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: hint,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                      ),
                      style: const TextStyle(fontSize: 15),
                    )
                  : Text(
                      value ?? '',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 15, color: Colors.black),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class SplitItemController {
  SplitItemController()
      : nameController = TextEditingController(),
        numberController = TextEditingController(),
        amountController = TextEditingController();

  final TextEditingController nameController;
  final TextEditingController numberController;
  final TextEditingController amountController;
  bool settled = false;

  void dispose() {
    nameController.dispose();
    numberController.dispose();
    amountController.dispose();
  }
}

enum ExtraType { none, split, loan }
enum SplitMode { equal, exact }
enum LoanType { lend, borrow }
enum LoanStatus { open, partial, closed }
