import 'package:flutter/material.dart';
import 'package:selavu/core/data/sms_repository.dart';
import 'package:selavu/core/data/transaction_repository.dart';
import 'package:selavu/core/model/sms_payload.dart';
import 'package:selavu/core/service/transaction_service.dart';
import 'package:selavu/core/util/sms_hash.dart';
import 'package:selavu/core/util/sms_parser.dart';
import 'package:selavu/route.dart';
import 'package:selavu/screen/transaction/add_transaction_screen.dart';
import 'package:selavu/screen/transaction/transaction_detail_screen.dart';
import 'package:selavu/screen/dashboard/widgets/expense_hero_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SmsRepository _repository = SmsRepository();
  final TransactionService _transactionService = TransactionService();
  List<DashboardItem> _items = <DashboardItem>[];
  double _rangeExpenseTotal = 0;
  double _monthExpenseTotal = 0;
  ExpenseRange _expenseRange = ExpenseRange.today;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<SmsItem> sms = await _repository.getBankTransactionMessages();
      final List<String> hashes = sms
          .map(
            (SmsItem item) => computeSmsHash(
              sender: item.sender,
              body: item.body,
              receivedAt: item.date,
            ),
          )
          .toList(growable: false);

      final Set<String> tracked = await _transactionService.getTrackedSmsHashes(hashes);
      final List<TransactionItem> transactions = await _transactionService.getTransactions();
      final DateTimeRange range = _getExpenseRangeDates(_expenseRange);
      final double rangeTotal = await _transactionService.getExpenseTotalBetween(start: range.start, end: range.end);
      final double monthTotal = await _transactionService.getMonthExpenseTotal();

      final List<DashboardItem> displayItems = <DashboardItem>[];
      for (int i = 0; i < sms.length; i++) {
        final SmsItem item = sms[i];
        final String hash = hashes[i];
        if (!tracked.contains(hash)) {
          displayItems.add(DashboardItem.sms(sms: item, hash: hash));
        }
      }

      for (final TransactionItem transaction in transactions) {
        displayItems.add(DashboardItem.transaction(transaction: transaction));
      }

      displayItems.sort((DashboardItem a, DashboardItem b) {
        if (a.kind != b.kind) {
          return a.kind == DashboardItemKind.sms ? -1 : 1;
        }
        final DateTime aDate = _getItemDate(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bDate = _getItemDate(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      setState(() {
        _items = displayItems;
        _rangeExpenseTotal = rangeTotal;
        _monthExpenseTotal = monthTotal;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : RefreshIndicator(
                    onRefresh: _loadDashboardData,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: ExpenseHeroCard(
                            monthTotal: _monthExpenseTotal,
                            periodTotal: _rangeExpenseTotal,
                            range: _expenseRange,
                            onRangeChanged: _handleExpenseRangeChange,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: InkWell(
                              onTap: () => Navigator.pushNamed(context, AppRoutes.analytics),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.withAlpha(20)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.analytics_outlined, color: Color(0xFF1B5E20), size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'View Detailed Analytics',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(child: _buildActionButtons()),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          sliver: SliverToBoxAdapter(
                            child: Row(
                              children: [
                                const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const Spacer(),
                                TextButton(onPressed: () {}, child: const Text('See All')),
                              ],
                            ),
                          ),
                        ),
                        _buildList(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _buildMainAction('Spent', Icons.upload_outlined, const Color(0xFFE53935), TransactionType.expense)),
          const SizedBox(width: 16),
          Expanded(child: _buildMainAction('Received', Icons.download_outlined, const Color(0xFF43A047), TransactionType.income)),
        ],
      ),
    );
  }

  Widget _buildMainAction(String label, IconData icon, Color color, TransactionType type) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.addTransaction, arguments: type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withAlpha(30)),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final List<DashboardItem> filteredItems = _applyDateFilter(_items);

    if (filteredItems.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('No transactions for this period', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final DashboardItem item = filteredItems[index];
            if (item.kind == DashboardItemKind.sms) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSmsCard(item.sms!),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTransactionCard(item.transaction!),
            );
          },
          childCount: filteredItems.length,
        ),
      ),
    );
  }

  Widget _buildSmsCard(SmsItem sms) {
    final double? amount = SmsParser.extractAmount(sms.body);
    final bool isCredit = SmsParser.isCredit(sms.body);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4), // Light yellow for attention
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withAlpha(50)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => isCredit ? _openIncomeFromSms(sms, amount, null) : _openExpenseFromSms(sms, amount, null),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                    child: const Text('UNTRACKED SMS', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  Text('₹${amount?.toStringAsFixed(2) ?? '??'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              ),
              const SizedBox(height: 12),
              Text(sms.sender, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text(sms.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[800], fontSize: 13, height: 1.4)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(_formatDate(sms.date), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const Spacer(),
                  const Text('Track Now', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.orange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(TransactionItem tx) {
    final bool isIncome = tx.type == 'income';
    final Color accent = isIncome ? const Color(0xFF43A047) : const Color(0xFFE53935);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withAlpha(20)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(2), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final bool? updated = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TransactionDetailScreen(transaction: tx)),
          );
          if (updated == true && mounted) _loadDashboardData();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(isIncome ? Icons.south_west : Icons.north_east, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.categoryName ?? tx.note ?? 'Transaction',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(tx.paymentMethodName ?? 'Unknown Method', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}₹${tx.amount.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: accent),
                  ),
                  const SizedBox(height: 4),
                  Text(_formatDateShort(tx.transactionDate), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(onPressed: _loadDashboardData, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }

  // Helper methods...
  List<DashboardItem> _applyDateFilter(List<DashboardItem> items) {
    final DateTimeRange range = _getExpenseRangeDates(_expenseRange);
    return items.where((item) {
      final DateTime? date = _getItemDate(item);
      if (date == null) return false;
      return date.isAtSameMomentAs(range.start) || (date.isAfter(range.start) && date.isBefore(range.end));
    }).toList();
  }

  Future<void> _handleExpenseRangeChange(ExpenseRange range) async {
    setState(() => _expenseRange = range);
    await _loadDashboardData();
  }

  DateTimeRange _getExpenseRangeDates(ExpenseRange range) {
    final DateTime now = DateTime.now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    switch (range) {
      case ExpenseRange.today:
        return DateTimeRange(start: todayStart, end: todayStart.add(const Duration(days: 1)));
      case ExpenseRange.past2Days:
        return DateTimeRange(start: todayStart.subtract(const Duration(days: 1)), end: todayStart.add(const Duration(days: 1)));
      case ExpenseRange.past4Days:
        return DateTimeRange(start: todayStart.subtract(const Duration(days: 3)), end: todayStart.add(const Duration(days: 1)));
      case ExpenseRange.week:
        return DateTimeRange(start: todayStart.subtract(const Duration(days: 6)), end: todayStart.add(const Duration(days: 1)));
    }
  }

  DateTime? _getItemDate(DashboardItem item) => item.kind == DashboardItemKind.sms ? item.sms?.date : item.transaction?.transactionDate;

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateShort(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}';
  }

  Future<void> _openExpenseFromSms(SmsItem sms, double? amount, String? counterparty) async {
    final bool? saved = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddTransactionScreen(smsPayload: SmsPayload(sender: sms.sender, body: sms.body, receivedAt: sms.date), initialAmount: amount, initialCounterparty: counterparty, initialType: TransactionType.expense)));
    if (saved == true && mounted) await _loadDashboardData();
  }

  Future<void> _openIncomeFromSms(SmsItem sms, double? amount, String? counterparty) async {
    final bool? saved = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddTransactionScreen(smsPayload: SmsPayload(sender: sms.sender, body: sms.body, receivedAt: sms.date), initialAmount: amount, initialCounterparty: counterparty, initialType: TransactionType.income)));
    if (saved == true && mounted) await _loadDashboardData();
  }
}

class DashboardItem {
  const DashboardItem.sms({required this.sms, required this.hash}) : kind = DashboardItemKind.sms, transaction = null;
  const DashboardItem.transaction({required this.transaction}) : kind = DashboardItemKind.transaction, sms = null, hash = null;
  final DashboardItemKind kind;
  final SmsItem? sms;
  final String? hash;
  final TransactionItem? transaction;
}

enum DashboardItemKind { sms, transaction }
