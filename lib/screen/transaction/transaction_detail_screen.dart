import 'package:flutter/material.dart';

import 'package:selavu/core/data/transaction_repository.dart';
import 'package:selavu/core/service/transaction_service.dart';

class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({super.key, required this.transaction});

  final TransactionItem transaction;

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final TransactionService _service = TransactionService();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  List<Category> _categories = <Category>[];
  List<PaymentMethod> _paymentMethods = <PaymentMethod>[];
  List<SplitItemDetail> _splitItems = <SplitItemDetail>[];

  String _type = 'expense';
  int? _selectedCategoryId;
  int? _selectedPaymentMethodId;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _type = widget.transaction.type;
    _amountController.text = widget.transaction.amount.toStringAsFixed(2);
    _noteController.text = widget.transaction.note ?? '';
    _selectedCategoryId = widget.transaction.categoryId;
    _selectedPaymentMethodId = widget.transaction.paymentMethodId;
    _loadLookups();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<Category> categories = _type == 'income'
          ? await _service.getIncomeCategories()
          : await _service.getExpenseCategories();
      final List<PaymentMethod> methods = await _service.getPaymentMethods();
      final List<SplitItemDetail> splitItems =
          await _service.getSplitItemsForTransaction(widget.transaction.id);

      setState(() {
        _categories = categories;
        _paymentMethods = methods;
        _splitItems = splitItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
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
      await _service.updateTransaction(
        id: widget.transaction.id,
        type: _type,
        amount: amount,
        categoryId: _selectedCategoryId,
        paymentMethodId: _selectedPaymentMethodId,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction updated.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Detail')),
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
    final TransactionItem tx = widget.transaction;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        DropdownButtonFormField<String>(
          value: _type,
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(
              value: 'expense',
              child: Text('Expense'),
            ),
            DropdownMenuItem<String>(
              value: 'income',
              child: Text('Income'),
            ),
          ],
          onChanged: (String? value) {
            if (value == null || value == _type) {
              return;
            }
            setState(() {
              _type = value;
              _selectedCategoryId = null;
            });
            _loadLookups();
          },
          decoration: const InputDecoration(
            labelText: 'Type',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
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
        DropdownButtonFormField<int>(
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
        if (_splitItems.isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          const Text('Split Details', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._splitItems.map(
            (SplitItemDetail item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(item.personName),
                subtitle: Text('Amount: ${item.amount.toStringAsFixed(2)}'),
                trailing: Text(
                  item.settled ? 'Settled' : 'Pending',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: item.settled ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ),
          ),
        ],
        if (tx.smsBody != null || tx.smsSender != null) ...<Widget>[
          const SizedBox(height: 20),
          const Text('Linked SMS', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildReadOnlyRow('Sender', tx.smsSender ?? 'Unknown'),
          _buildReadOnlyRow('Received', _formatDate(tx.smsReceivedAt)),
          _buildReadOnlyRow('Body', tx.smsBody ?? ''),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isSaving ? null : _saveTransaction,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }

  Widget _buildReadOnlyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Unknown date';
    }

    final String twoDigitMonth = date.month.toString().padLeft(2, '0');
    final String twoDigitDay = date.day.toString().padLeft(2, '0');
    final String twoDigitHour = date.hour.toString().padLeft(2, '0');
    final String twoDigitMinute = date.minute.toString().padLeft(2, '0');
    return '${date.year}-$twoDigitMonth-$twoDigitDay $twoDigitHour:$twoDigitMinute';
  }
}
