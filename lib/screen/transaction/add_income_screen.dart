import 'package:flutter/material.dart';

import 'package:selavu/core/data/transaction_repository.dart';
import 'package:selavu/core/service/transaction_service.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final TransactionService _service = TransactionService();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  List<Category> _categories = <Category>[];
  List<PaymentMethod> _paymentMethods = <PaymentMethod>[];

  int? _selectedCategoryId;
  int? _selectedPaymentMethodId;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
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
      final List<Category> categories = await _service.getIncomeCategories();
      final List<PaymentMethod> methods = await _service.getPaymentMethods();

      setState(() {
        _categories = categories;
        _paymentMethods = methods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
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

  Future<void> _saveIncome() async {
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
      await _service.addIncomeWithDetails(
        amount: amount,
        categoryId: _selectedCategoryId,
        paymentMethodId: _selectedPaymentMethodId,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Income saved.')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Income')),
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
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isSaving ? null : _saveIncome,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Income'),
        ),
      ],
    );
  }
}
