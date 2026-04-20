import 'package:flutter/material.dart';
import 'package:selavu/core/data/sms_repository.dart';
import 'package:selavu/core/data/transaction_repository.dart';
import 'package:selavu/core/model/sms_payload.dart';
import 'package:selavu/core/service/transaction_service.dart';
import 'package:selavu/core/util/sms_hash.dart';
import 'package:selavu/route.dart';
import 'package:selavu/screen/transaction/add_expense_screen.dart';
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
			final double rangeTotal = await _transactionService.getExpenseTotalBetween(
				start: range.start,
				end: range.end,
			);
			final double monthTotal = await _transactionService.getMonthExpenseTotal();

			final List<DashboardItem> displayItems = <DashboardItem>[];
			for (int i = 0; i < sms.length; i++) {
				final SmsItem item = sms[i];
				final String hash = hashes[i];
				if (!tracked.contains(hash)) {
					displayItems.add(
						DashboardItem.sms(
							sms: item,
							hash: hash,
						),
					);
				}
			}

			for (final TransactionItem transaction in transactions) {
				displayItems.add(
					DashboardItem.transaction(transaction: transaction),
				);
			}

			displayItems.sort((DashboardItem a, DashboardItem b) {
				if (a.kind != b.kind) {
					return a.kind == DashboardItemKind.sms ? -1 : 1;
				}
				final DateTime aDate = _getItemDate(a) ??
					DateTime.fromMillisecondsSinceEpoch(0);
				final DateTime bDate = _getItemDate(b) ??
					DateTime.fromMillisecondsSinceEpoch(0);
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
			body: _buildBody(context),
		);
	}

	Widget _buildBody(BuildContext context) {
		if (_isLoading) {
			return const Center(child: CircularProgressIndicator());
		}

		if (_error != null) {
			return Center(
				child: Padding(
					padding: const EdgeInsets.all(24),
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: <Widget>[
							Text(
								_error!,
								textAlign: TextAlign.center,
							),
							const SizedBox(height: 12),
							FilledButton(
								onPressed: _loadDashboardData,
								child: const Text('Try Again'),
							),
						],
					),
				),
			);
		}

		final List<DashboardItem> filteredItems = _applyDateFilter(_items);

		return Column(
			children: <Widget>[
				ExpenseHeroCard(
					monthTotal: _monthExpenseTotal,
					periodTotal: _rangeExpenseTotal,
					range: _expenseRange,
					onRangeChanged: _handleExpenseRangeChange,
				),
				Padding(
					padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
					child: Row(
						children: <Widget>[
							Expanded(
								child: SizedBox(
									height: 56,
									child: FilledButton(
										onPressed: () => Navigator.of(context).pushNamed(
											AppRoutes.addExpense,
										),
										style: FilledButton.styleFrom(
											backgroundColor: const Color(0xFF44444C),
											foregroundColor: Colors.white,
											textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
											shape: RoundedRectangleBorder(
												borderRadius: BorderRadius.circular(14),
											),
										),
										child: const Text('Spent'),
									),
								),
							),
							const SizedBox(width: 12),
							Expanded(
								child: SizedBox(
									height: 56,
									child: FilledButton(
										onPressed: () => Navigator.of(context).pushNamed(
											AppRoutes.addIncome,
										),
										style: FilledButton.styleFrom(
											backgroundColor: const Color(0xFF44444C),
											foregroundColor: Colors.white,
											textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
											shape: RoundedRectangleBorder(
												borderRadius: BorderRadius.circular(14),
											),
										),
										child: const Text('Received'),
									),
								),
							),
						],
					),
				),
				Expanded(
					child: filteredItems.isEmpty
						? const Center(child: Text('No untracked SMS or transactions found.'))
						: RefreshIndicator(
							onRefresh: _loadDashboardData,
							child: ListView.separated(
								padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
								itemCount: filteredItems.length,
								separatorBuilder: (_, _) => const SizedBox(height: 10),
								itemBuilder: (BuildContext context, int index) {
											final DashboardItem item = filteredItems[index];
											if (item.kind == DashboardItemKind.sms) {
												final SmsItem sms = item.sms!;
												return _buildSmsExpenseCard(context, sms);
											}

											final TransactionItem transaction = item.transaction!;
											final bool isIncome = transaction.type == 'income';
											final String amountLabel =
												'${isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(2)}';
											final String title = transaction.categoryName ??
												(transaction.note?.isNotEmpty == true ? transaction.note! : 'Transaction');

											return _buildTransactionCard(
												context,
												transaction: transaction,
												title: title,
												amountLabel: amountLabel,
												isIncome: isIncome,
											);
								},
							),
						),
				),
			],
		);
	}

	Widget _buildSmsExpenseCard(BuildContext context, SmsItem sms) {
		final ColorScheme scheme = Theme.of(context).colorScheme;
		return Material(
			color: scheme.surface,
			borderRadius: BorderRadius.circular(16),
			child: InkWell(
				borderRadius: BorderRadius.circular(16),
				onTap: () => Navigator.of(context).push(
					MaterialPageRoute<bool?>(
						builder: (_) => AddExpenseScreen(
							smsPayload: SmsPayload(
								sender: sms.sender,
								body: sms.body,
								receivedAt: sms.date,
							),
						),
					),
				),
				child: Container(
					padding: const EdgeInsets.all(14),
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(16),
						border: Border.all(color: scheme.outlineVariant),
					),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: <Widget>[
							Row(
								children: <Widget>[
									Container(
										padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
										decoration: BoxDecoration(
											color: scheme.errorContainer,
											borderRadius: BorderRadius.circular(999),
										),
										child: Text(
											'Untracked SMS',
											style: Theme.of(context).textTheme.labelSmall?.copyWith(
												color: scheme.onErrorContainer,
												fontWeight: FontWeight.w700,
											),
										),
									),
									const Spacer(),
									Icon(Icons.chevron_right, color: scheme.outline),
								],
							),
							const SizedBox(height: 10),
							Text(
								sms.sender,
								maxLines: 1,
								overflow: TextOverflow.ellipsis,
								style: Theme.of(context).textTheme.titleSmall?.copyWith(
									fontWeight: FontWeight.w700,
								),
							),
							const SizedBox(height: 6),
							Text(
								sms.body,
								maxLines: 2,
								overflow: TextOverflow.ellipsis,
								style: Theme.of(context).textTheme.bodyMedium,
							),
							const SizedBox(height: 8),
							Text(
								_formatDate(sms.date),
								style: Theme.of(context).textTheme.labelMedium,
							),
						],
					),
				),
			),
		);
	}

	Widget _buildTransactionCard(
		BuildContext context, {
		required TransactionItem transaction,
		required String title,
		required String amountLabel,
		required bool isIncome,
	}) {
		final ColorScheme scheme = Theme.of(context).colorScheme;
		final Color accent = isIncome ? scheme.secondary : scheme.error;

		return Material(
			color: scheme.surface,
			borderRadius: BorderRadius.circular(16),
			child: InkWell(
				borderRadius: BorderRadius.circular(16),
				onTap: () async {
					final bool? updated = await Navigator.of(context).push(
						MaterialPageRoute<bool>(
							builder: (_) => TransactionDetailScreen(
								transaction: transaction,
							),
						),
					);
					if (updated == true && context.mounted) {
						await _loadDashboardData();
					}
				},
				child: Container(
					padding: const EdgeInsets.all(14),
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(16),
						border: Border.all(color: scheme.outlineVariant),
					),
					child: Row(
						children: <Widget>[
							Container(
								width: 36,
								height: 36,
								decoration: BoxDecoration(
									color: accent.withOpacity(0.12),
									borderRadius: BorderRadius.circular(10),
								),
								child: Icon(
									isIncome ? Icons.south_west : Icons.north_east,
									color: accent,
									size: 18,
								),
							),
							const SizedBox(width: 12),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: <Widget>[
										Text(
											title,
											maxLines: 1,
											overflow: TextOverflow.ellipsis,
											style: Theme.of(context).textTheme.titleSmall?.copyWith(
												fontWeight: FontWeight.w700,
											),
										),
										const SizedBox(height: 4),
										Text(
											transaction.paymentMethodName ?? 'Payment method',
											maxLines: 1,
											overflow: TextOverflow.ellipsis,
											style: Theme.of(context).textTheme.bodySmall,
										),
										const SizedBox(height: 2),
										Text(
											_formatDate(transaction.transactionDate),
											style: Theme.of(context).textTheme.labelMedium,
										),
									],
								),
							),
							Text(
								amountLabel,
								style: Theme.of(context).textTheme.titleSmall?.copyWith(
									color: accent,
									fontWeight: FontWeight.w800,
								),
							),
						],
					),
				),
			),
		);
	}



	List<DashboardItem> _applyDateFilter(List<DashboardItem> items) {
		final DateTimeRange range = _getExpenseRangeDates(_expenseRange);
		return items.where((DashboardItem item) {
			final DateTime? itemDate = _getItemDate(item);
			if (itemDate == null) {
				return false;
			}
			return itemDate.isAtSameMomentAs(range.start) ||
				(itemDate.isAfter(range.start) && itemDate.isBefore(range.end));
		}).toList(growable: false);
	}

	Future<void> _handleExpenseRangeChange(ExpenseRange range) async {
		setState(() {
			_expenseRange = range;
		});
		await _loadDashboardData();
	}

	DateTimeRange _getExpenseRangeDates(ExpenseRange range) {
		final DateTime now = DateTime.now();
		final DateTime todayStart = DateTime(now.year, now.month, now.day);
		switch (range) {
			case ExpenseRange.today:
				return DateTimeRange(
					start: todayStart,
					end: todayStart.add(const Duration(days: 1)),
				);
			case ExpenseRange.yesterday:
				final DateTime start = todayStart.subtract(const Duration(days: 1));
				return DateTimeRange(
					start: start,
					end: todayStart,
				);
			case ExpenseRange.past2Days:
				final DateTime start = todayStart.subtract(const Duration(days: 1));
				return DateTimeRange(
					start: start,
					end: todayStart.add(const Duration(days: 1)),
				);
			case ExpenseRange.past3Days:
				final DateTime start = todayStart.subtract(const Duration(days: 2));
				return DateTimeRange(
					start: start,
					end: todayStart.add(const Duration(days: 1)),
				);
		}
	}

	DateTime? _getItemDate(DashboardItem item) {
		if (item.kind == DashboardItemKind.sms) {
			return item.sms?.date;
		}
		return item.transaction?.transactionDate;
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


class DashboardItem {
	const DashboardItem.sms({
		required this.sms,
		required this.hash,
	})  : kind = DashboardItemKind.sms,
			transaction = null;

	const DashboardItem.transaction({
		required this.transaction,
	})  : kind = DashboardItemKind.transaction,
			sms = null,
			hash = null;

	final DashboardItemKind kind;
	final SmsItem? sms;
	final String? hash;
	final TransactionItem? transaction;
}

enum DashboardItemKind {
	sms,
	transaction,
}

