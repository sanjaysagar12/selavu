import 'package:flutter/material.dart';
import 'package:selavu/core/data/sms_repository.dart';
import 'package:selavu/core/data/transaction_repository.dart';
import 'package:selavu/core/model/sms_payload.dart';
import 'package:selavu/core/service/transaction_service.dart';
import 'package:selavu/core/util/sms_hash.dart';
import 'package:selavu/route.dart';
import 'package:selavu/screen/transaction/add_expense_screen.dart';
import 'package:selavu/screen/transaction/transaction_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
	const DashboardScreen({super.key});

	@override
	State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
	final SmsRepository _repository = SmsRepository();
	final TransactionService _transactionService = TransactionService();
	List<DashboardItem> _items = <DashboardItem>[];
	DateFilter _dateFilter = DateFilter.today;
	DateTime? _selectedDate;
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
			appBar: AppBar(
				title: const Text('Dashboard'),
				actions: <Widget>[
					IconButton(
						onPressed: _loadDashboardData,
						icon: const Icon(Icons.refresh),
						tooltip: 'Refresh',
					),
				],
			),
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
				Padding(
					padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
					child: Row(
						children: <Widget>[
							Expanded(
								child: FilledButton.icon(
									onPressed: () => Navigator.of(context).pushNamed(
										AppRoutes.addExpense,
									),
									icon: const Icon(Icons.remove_circle_outline),
									label: const Text('Spent'),
								),
							),
							const SizedBox(width: 12),
							Expanded(
								child: FilledButton.icon(
									onPressed: () => Navigator.of(context).pushNamed(
										AppRoutes.addIncome,
									),
									icon: const Icon(Icons.add_circle_outline),
									label: const Text('Received'),
								),
							),
						],
					),
				),
				Padding(
					padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
					child: Row(
						children: <Widget>[
							Expanded(
								child: DropdownButtonFormField<DateFilter>(
									value: _dateFilter,
									decoration: const InputDecoration(
										labelText: 'Filter',
										border: OutlineInputBorder(),
									),
									onChanged: (DateFilter? value) {
										if (value == null) {
											return;
										}
										setState(() {
											_dateFilter = value;
											if (value != DateFilter.custom) {
												_selectedDate = null;
											}
										});
									},
									items: const <DropdownMenuItem<DateFilter>>[
										DropdownMenuItem<DateFilter>(
											value: DateFilter.all,
											child: Text('All'),
										),
										DropdownMenuItem<DateFilter>(
											value: DateFilter.today,
											child: Text('Today'),
										),
										DropdownMenuItem<DateFilter>(
											value: DateFilter.yesterday,
											child: Text('Yesterday'),
										),
										DropdownMenuItem<DateFilter>(
											value: DateFilter.custom,
											child: Text('Pick date'),
										),
									],
								),
							),
							const SizedBox(width: 12),
							FilledButton(
								onPressed: _dateFilter == DateFilter.custom
									? () => _pickCustomDate(context)
									: null,
								child: Text(
									_selectedDate == null
										? 'Select'
										: _formatDateShort(_selectedDate!),
								),
							),
						],
					),
				),
				Padding(
					padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
					child: Text(
						'Untracked SMS on top. Tracked items show from transactions.',
						style: Theme.of(context).textTheme.bodySmall,
					),
				),
				Expanded(
					child: filteredItems.isEmpty
						? const Center(child: Text('No untracked SMS or transactions found.'))
						: RefreshIndicator(
							onRefresh: _loadDashboardData,
							child: ListView.separated(
								itemCount: filteredItems.length,
								separatorBuilder: (_, _) => const Divider(height: 1),
								itemBuilder: (BuildContext context, int index) {
											final DashboardItem item = filteredItems[index];
											if (item.kind == DashboardItemKind.sms) {
												final SmsItem sms = item.sms!;
												return ListTile(
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
												title: Text(
													sms.sender,
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
												),
												subtitle: Column(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: <Widget>[
														Text(
															sms.body,
															maxLines: 2,
															overflow: TextOverflow.ellipsis,
														),
														const SizedBox(height: 4),
														Text(
															'Untracked',
															style: TextStyle(
																color: Theme.of(context).colorScheme.error,
																fontWeight: FontWeight.w600,
															),
														),
														const SizedBox(height: 4),
														Text(
															_formatDate(sms.date),
															style: Theme.of(context).textTheme.labelMedium,
														),
													],
												),
												isThreeLine: true,
											);
											}

											final TransactionItem transaction = item.transaction!;
											final bool isIncome = transaction.type == 'income';
											final String amountLabel =
												'${isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(2)}';
											final String title = transaction.categoryName ??
												(transaction.note?.isNotEmpty == true ? transaction.note! : 'Transaction');

											return ListTile(
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
												title: Text(
													title,
													maxLines: 1,
													overflow: TextOverflow.ellipsis,
												),
												subtitle: Column(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: <Widget>[
														Text(
															transaction.paymentMethodName ?? 'Payment method',
														),
														const SizedBox(height: 4),
														Text(
															_formatDate(transaction.transactionDate),
															style: Theme.of(context).textTheme.labelMedium,
														),
													],
												),
												trailing: Text(
													amountLabel,
													style: TextStyle(
														color: isIncome
															? Theme.of(context).colorScheme.secondary
															: Theme.of(context).colorScheme.error,
														fontWeight: FontWeight.w600,
													),
												),
												isThreeLine: true,
											);
								},
							),
						),
				),
			],
		);
	}

	Future<void> _pickCustomDate(BuildContext context) async {
		final DateTime now = DateTime.now();
		final DateTime? picked = await showDatePicker(
			context: context,
			initialDate: _selectedDate ?? now,
			firstDate: DateTime(now.year - 5),
			lastDate: DateTime(now.year + 1),
		);

		if (picked == null) {
			return;
		}

		setState(() {
			_selectedDate = picked;
			_dateFilter = DateFilter.custom;
		});
	}

	List<DashboardItem> _applyDateFilter(List<DashboardItem> items) {
		if (_dateFilter == DateFilter.all) {
			return items;
		}

		final DateTime now = DateTime.now();
		DateTime? targetDate;
		if (_dateFilter == DateFilter.today) {
			targetDate = DateTime(now.year, now.month, now.day);
		} else if (_dateFilter == DateFilter.yesterday) {
			final DateTime yesterday = now.subtract(const Duration(days: 1));
			targetDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
		} else if (_dateFilter == DateFilter.custom) {
			if (_selectedDate == null) {
				return items;
			}
			targetDate = DateTime(
				_selectedDate!.year,
				_selectedDate!.month,
				_selectedDate!.day,
			);
		}

		if (targetDate == null) {
			return items;
		}

		return items.where((DashboardItem item) {
			final DateTime? itemDate = _getItemDate(item);
			if (itemDate == null) {
				return false;
			}
			final DateTime normalized = DateTime(
				itemDate.year,
				itemDate.month,
				itemDate.day,
			);
			return normalized == targetDate;
		}).toList(growable: false);
	}

	DateTime? _getItemDate(DashboardItem item) {
		if (item.kind == DashboardItemKind.sms) {
			return item.sms?.date;
		}
		return item.transaction?.transactionDate;
	}

	String _formatDateShort(DateTime date) {
		final String twoDigitMonth = date.month.toString().padLeft(2, '0');
		final String twoDigitDay = date.day.toString().padLeft(2, '0');
		return '${date.year}-$twoDigitMonth-$twoDigitDay';
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

enum DateFilter {
	all,
	today,
	yesterday,
	custom,
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

