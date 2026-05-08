import 'package:flutter/material.dart';
import 'package:selavu/core/data/transaction_repository.dart';
import 'package:selavu/core/service/transaction_service.dart';
import 'package:selavu/core/util/ui_util.dart';
import 'package:selavu/screen/transaction/widgets/category_selector.dart';
import 'package:selavu/screen/transaction/widgets/payment_method_selector.dart';
import 'package:selavu/screen/transaction/widgets/split_detail_list.dart';

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
  final TextEditingController _counterpartyController = TextEditingController();

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
    _counterpartyController.text = widget.transaction.counterparty ?? '';
    _selectedCategoryId = widget.transaction.categoryId;
    _selectedPaymentMethodId = widget.transaction.paymentMethodId;
    _loadLookups();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _counterpartyController.dispose();
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

    setState(() => _isSaving = true);

    try {
      await _service.updateTransaction(
        id: widget.transaction.id,
        type: _type,
        amount: amount,
        categoryId: _selectedCategoryId,
        paymentMethodId: _selectedPaymentMethodId,
        counterparty: _counterpartyController.text.trim().isEmpty
            ? null
            : _counterpartyController.text.trim(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction updated.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteTransaction() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
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

    if (confirm != true) return;

    try {
      await _service.deleteTransaction(widget.transaction.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Transaction Detail', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _deleteTransaction,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
      bottomNavigationBar: _isLoading || _error != null ? null : _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: FilledButton(
          onPressed: _isSaving ? null : _saveTransaction,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isSaving
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(_error ?? 'An error occurred', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          FilledButton(onPressed: _loadLookups, child: const Text('Try Again')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final Category? category = _categories.cast<Category?>().firstWhere(
          (c) => c?.id == _selectedCategoryId,
          orElse: () => null,
        );
    final Color color = UIUtil.hexToColor(category?.color);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withAlpha(200)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: color.withAlpha(80), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withAlpha(50),
                  child: Icon(UIUtil.getIconData(category?.icon), color: Colors.white, size: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  '₹${_amountController.text}',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text(
                  category?.name ?? 'Uncategorized',
                  style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, color: Colors.white, size: 12),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(widget.transaction.transactionDate),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Main Info
          _buildSectionTitle('TRANSACTION INFO'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withAlpha(30)),
            ),
            child: Column(
              children: [
                _buildFieldWrapper(
                  label: 'Amount',
                  icon: Icons.currency_rupee,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                  ),
                ),
                const Divider(height: 24),
                CategorySelector(
                  categories: _categories,
                  selectedCategoryId: _selectedCategoryId,
                  onCategorySelected: (cat) => setState(() => _selectedCategoryId = cat.id),
                  onRefresh: _loadLookups,
                ),
                const Divider(height: 32),
                PaymentMethodSelector(
                  paymentMethods: _paymentMethods,
                  selectedPaymentMethodId: _selectedPaymentMethodId,
                  onPaymentMethodSelected: (m) => setState(() => _selectedPaymentMethodId = m.id),
                  onRefresh: _loadLookups,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details
          _buildSectionTitle('ADDITIONAL DETAILS'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withAlpha(30)),
            ),
            child: Column(
              children: [
                _buildFieldWrapper(
                  label: _type == 'income' ? 'Received from' : 'Paid to',
                  icon: Icons.person_outline,
                  child: TextField(
                    controller: _counterpartyController,
                    style: const TextStyle(fontSize: 15),
                    decoration: const InputDecoration(hintText: 'Enter name', isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                  ),
                ),
                const Divider(height: 32),
                _buildFieldWrapper(
                  label: 'Note',
                  icon: Icons.notes,
                  child: TextField(
                    controller: _noteController,
                    style: const TextStyle(fontSize: 15),
                    decoration: const InputDecoration(hintText: 'Add a note', isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                  ),
                ),
              ],
            ),
          ),

          if (_splitItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('SPLIT DETAILS'),
            const SizedBox(height: 8),
            SplitDetailList(items: _splitItems),
          ],

          if (widget.transaction.smsBody != null) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('ORIGINAL SMS'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withAlpha(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sms_outlined, size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text(widget.transaction.smsSender ?? 'Unknown Sender', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                      const Spacer(),
                      Text(_formatDate(widget.transaction.smsReceivedAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(widget.transaction.smsBody!, style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.4)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
    );
  }

  Widget _buildFieldWrapper({required String label, required IconData icon, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              child,
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    final String twoDigitMonth = date.month.toString().padLeft(2, '0');
    final String twoDigitDay = date.day.toString().padLeft(2, '0');
    final String twoDigitHour = date.hour.toString().padLeft(2, '0');
    final String twoDigitMinute = date.minute.toString().padLeft(2, '0');
    return '${date.year}-$twoDigitMonth-$twoDigitDay $twoDigitHour:$twoDigitMinute';
  }
}
