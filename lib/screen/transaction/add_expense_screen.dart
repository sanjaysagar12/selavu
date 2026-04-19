import 'package:flutter/material.dart';

import 'package:selavu/core/data/transaction_repository.dart';
import 'package:selavu/core/model/sms_payload.dart';
import 'package:selavu/core/service/transaction_service.dart';
import 'package:selavu/core/util/sms_hash.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.smsPayload});

  final SmsPayload? smsPayload;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TransactionService _service = TransactionService();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final TextEditingController _loanPersonController = TextEditingController();
  final TextEditingController _loanPrincipalController = TextEditingController();
  final TextEditingController _loanOutstandingController = TextEditingController();
  final TextEditingController _loanNoteController = TextEditingController();

  List<Category> _categories = <Category>[];
  List<PaymentMethod> _paymentMethods = <PaymentMethod>[];

  int? _selectedCategoryId;
  int? _selectedPaymentMethodId;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  ExtraType _extraType = ExtraType.none;
  SplitMode _splitMode = SplitMode.equal;
  final List<SplitItemController> _splitItems = <SplitItemController>[];

  LoanType _loanType = LoanType.lend;
  LoanStatus _loanStatus = LoanStatus.open;

  @override
  void initState() {
    super.initState();
    _loadLookups();
    _prefillFromSms();
    _addSplitItem();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _loanPersonController.dispose();
    _loanPrincipalController.dispose();
    _loanOutstandingController.dispose();
    _loanNoteController.dispose();
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
      final List<Category> categories = await _service.getExpenseCategories();
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

  void _prefillFromSms() {
    final SmsPayload? sms = widget.smsPayload;
    if (sms == null) {
      return;
    }

    if (_noteController.text.trim().isEmpty) {
      _noteController.text = sms.body;
    }

    if (_amountController.text.trim().isEmpty) {
      final double? amount = _extractAmountFromSms(sms.body);
      if (amount != null) {
        _amountController.text = amount.toStringAsFixed(2);
      }
    }
  }

  double? _extractAmountFromSms(String body) {
    final RegExp rupeePattern = RegExp(
      r'(?:inr|rs\.?|rs)\s*([0-9,]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    final RegExp reversePattern = RegExp(
      r'([0-9,]+(?:\.[0-9]{1,2})?)\s*(?:inr|rs\.?|rs)',
      caseSensitive: false,
    );

    final RegExpMatch? match = rupeePattern.firstMatch(body) ??
        reversePattern.firstMatch(body);
    if (match == null) {
      return null;
    }

    final String raw = match.group(1) ?? '';
    if (raw.isEmpty) {
      return null;
    }

    final String normalized = raw.replaceAll(',', '');
    return double.tryParse(normalized);
  }

  void _addSplitItem() {
    setState(() {
      _splitItems.add(SplitItemController());
    });
  }

  void _removeSplitItem(int index) {
    setState(() {
      final SplitItemController item = _splitItems.removeAt(index);
      item.dispose();
    });
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
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a payment method name.')),
      );
      return;
    }

    try {
      final int newId = await _service.addPaymentMethod(name);
      final List<PaymentMethod> methods = await _service.getPaymentMethods();
      if (!context.mounted) {
        return;
      }
      setState(() {
        _paymentMethods = methods;
        _selectedPaymentMethodId = newId;
      });
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add method: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveExpense() async {
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
      final double? principal = double.tryParse(_loanPrincipalController.text.trim());
      final double? outstanding =
          double.tryParse(_loanOutstandingController.text.trim());

      if (personName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a person name for the loan.')),
        );
        return;
      }

      if (principal == null || principal <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid principal amount.')),
        );
        return;
      }

      if (outstanding == null || outstanding < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid outstanding amount.')),
        );
        return;
      }

      loanInput = LoanTransactionInput(
        personName: personName,
        loanType: _loanType == LoanType.lend ? 'lend' : 'borrow',
        principalAmount: principal,
        outstandingAmount: outstanding,
        status: _loanStatus.name,
        note: _loanNoteController.text.trim().isEmpty
            ? null
            : _loanNoteController.text.trim(),
      );
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

      await _service.addExpenseWithExtras(
        amount: amount,
        categoryId: _selectedCategoryId,
        paymentMethodId: _selectedPaymentMethodId,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        smsHash: smsHash,
        smsSender: sms?.sender,
        smsBody: sms?.body,
        smsReceivedAt: sms?.receivedAt,
        split: splitInput,
        loan: loanInput,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense saved.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!context.mounted) {
        return;
      }
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
    final int count = _splitItems.length;

    if (count == 0) {
      return items;
    }

    final double equalShare = totalAmount / count;

    for (final SplitItemController item in _splitItems) {
      final String name = item.nameController.text.trim();
      if (name.isEmpty) {
        continue;
      }

      double amount = 0;
      final double? parsed = double.tryParse(item.amountController.text.trim());
      if (_splitMode == SplitMode.equal) {
        amount = equalShare;
      } else if (parsed != null && parsed >= 0) {
        amount = parsed;
      }

      items.add(
        SplitItemInput(
          personName: name,
          amount: amount,
          isPayer: item.isPayer,
          settled: item.settled,
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        if (widget.smsPayload != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Linked to SMS. Payment method set to UPI.'),
          ),
        DropdownButtonFormField<int>(
          value: _selectedCategoryId,
          items: _categories
              .map(
                (Category category) => DropdownMenuItem<int>(
                  value: category.id,
                  child: Text(category.name),
                ),
              )
              .toList(growable: false),
          onChanged: (int? value) {
            setState(() {
              _selectedCategoryId = value;
            });
          },
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedPaymentMethodId,
                items: _paymentMethods
                    .map(
                      (PaymentMethod method) => DropdownMenuItem<int>(
                        value: method.id,
                        child: Text(method.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (int? value) {
                  setState(() {
                    _selectedPaymentMethodId = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Payment method',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _promptAddPaymentMethod,
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Extras', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SegmentedButton<ExtraType>(
          segments: const <ButtonSegment<ExtraType>>[
            ButtonSegment<ExtraType>(value: ExtraType.none, label: Text('None')),
            ButtonSegment<ExtraType>(value: ExtraType.split, label: Text('Split')),
            ButtonSegment<ExtraType>(value: ExtraType.loan, label: Text('Loan')),
          ],
          selected: <ExtraType>{_extraType},
          onSelectionChanged: (Set<ExtraType> selection) {
            setState(() {
              _extraType = selection.first;
            });
          },
        ),
        const SizedBox(height: 12),
        if (_extraType == ExtraType.split) _buildSplitSection(),
        if (_extraType == ExtraType.loan) _buildLoanSection(),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isSaving ? null : _saveExpense,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Expense'),
        ),
      ],
    );
  }

  Widget _buildSplitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DropdownButtonFormField<SplitMode>(
          value: _splitMode,
          items: const <DropdownMenuItem<SplitMode>>[
            DropdownMenuItem<SplitMode>(
              value: SplitMode.equal,
              child: Text('Equal split'),
            ),
            DropdownMenuItem<SplitMode>(
              value: SplitMode.exact,
              child: Text('Exact amounts'),
            ),
          ],
          onChanged: (SplitMode? value) {
            if (value == null) {
              return;
            }
            setState(() {
              _splitMode = value;
            });
          },
          decoration: const InputDecoration(
            labelText: 'Split mode',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        ..._splitItems.asMap().entries.map(
          (MapEntry<int, SplitItemController> entry) {
            final int index = entry.key;
            final SplitItemController item = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: item.nameController,
                          decoration: InputDecoration(
                            labelText: 'Person ${index + 1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _splitItems.length > 1
                            ? () => _removeSplitItem(index)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        tooltip: 'Remove',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: item.amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (for exact mode)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: CheckboxListTile(
                          value: item.isPayer,
                          onChanged: (bool? value) {
                            setState(() {
                              item.isPayer = value ?? false;
                            });
                          },
                          title: const Text('Is payer'),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          value: item.settled,
                          onChanged: (bool? value) {
                            setState(() {
                              item.settled = value ?? false;
                            });
                          },
                          title: const Text('Settled'),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        OutlinedButton.icon(
          onPressed: _addSplitItem,
          icon: const Icon(Icons.add),
          label: const Text('Add Person'),
        ),
      ],
    );
  }

  Widget _buildLoanSection() {
    return Column(
      children: <Widget>[
        TextField(
          controller: _loanPersonController,
          decoration: const InputDecoration(
            labelText: 'Person name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<LoanType>(
          value: _loanType,
          items: const <DropdownMenuItem<LoanType>>[
            DropdownMenuItem<LoanType>(
              value: LoanType.lend,
              child: Text('Lend'),
            ),
            DropdownMenuItem<LoanType>(
              value: LoanType.borrow,
              child: Text('Borrow'),
            ),
          ],
          onChanged: (LoanType? value) {
            if (value == null) {
              return;
            }
            setState(() {
              _loanType = value;
            });
          },
          decoration: const InputDecoration(
            labelText: 'Loan type',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _loanPrincipalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Principal amount',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _loanOutstandingController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Outstanding amount',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<LoanStatus>(
          value: _loanStatus,
          items: const <DropdownMenuItem<LoanStatus>>[
            DropdownMenuItem<LoanStatus>(
              value: LoanStatus.open,
              child: Text('Open'),
            ),
            DropdownMenuItem<LoanStatus>(
              value: LoanStatus.partial,
              child: Text('Partial'),
            ),
            DropdownMenuItem<LoanStatus>(
              value: LoanStatus.closed,
              child: Text('Closed'),
            ),
          ],
          onChanged: (LoanStatus? value) {
            if (value == null) {
              return;
            }
            setState(() {
              _loanStatus = value;
            });
          },
          decoration: const InputDecoration(
            labelText: 'Status',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _loanNoteController,
          decoration: const InputDecoration(
            labelText: 'Loan note (optional)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

class SplitItemController {
  SplitItemController()
      : nameController = TextEditingController(),
        amountController = TextEditingController();

  final TextEditingController nameController;
  final TextEditingController amountController;
  bool isPayer = false;
  bool settled = false;

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}

enum ExtraType {
  none,
  split,
  loan,
}

enum SplitMode {
  equal,
  exact,
}

enum LoanType {
  lend,
  borrow,
}

enum LoanStatus {
  open,
  partial,
  closed,
}
