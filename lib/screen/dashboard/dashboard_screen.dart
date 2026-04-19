import 'package:flutter/material.dart';
import 'package:selavu/core/data/sms_repository.dart';
import 'package:selavu/core/model/sms_payload.dart';
import 'package:selavu/core/service/transaction_service.dart';
import 'package:selavu/core/util/sms_hash.dart';
import 'package:selavu/route.dart';
import 'package:selavu/screen/transaction/add_expense_screen.dart';

class DashboardScreen extends StatefulWidget {
	const DashboardScreen({super.key});

	@override
	State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
	final SmsRepository _repository = SmsRepository();
	final TransactionService _transactionService = TransactionService();
	List<SmsDisplayItem> _items = <SmsDisplayItem>[];
	DateFilter _dateFilter = DateFilter.today;
	DateTime? _selectedDate;
	bool _isLoading = true;
	String? _error;

	@override
	void initState() {
		super.initState();
		_loadSms();
	}

	Future<void> _loadSms() async {
		setState(() {
			_isLoading = true;
			_error = null;
		});

		try {
			final List<SmsItem> sms = await _repository.getBankTransactionSms();
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

			final List<SmsDisplayItem> displayItems = <SmsDisplayItem>[];
			for (int i = 0; i < sms.length; i++) {
				final SmsItem item = sms[i];
				final String hash = hashes[i];
				displayItems.add(
					SmsDisplayItem(
						sms: item,
						hash: hash,
						tracked: tracked.contains(hash),
					),
				);
			}

			displayItems.sort((SmsDisplayItem a, SmsDisplayItem b) {
				if (a.tracked != b.tracked) {
					return a.tracked ? 1 : -1;
				}
				final DateTime aDate = a.sms.date ?? DateTime.fromMillisecondsSinceEpoch(0);
				final DateTime bDate = b.sms.date ?? DateTime.fromMillisecondsSinceEpoch(0);
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
						onPressed: _loadSms,
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
								onPressed: _loadSms,
								child: const Text('Try Again'),
							),
						],
					),
				),
			);
		}

		final List<SmsDisplayItem> filteredItems = _applyDateFilter(_items);

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
						'Untracked expense on top',
						style: Theme.of(context).textTheme.bodySmall,
					),
				),
				Expanded(
					child: filteredItems.isEmpty
						? const Center(child: Text('No bank credit/debit SMS found.'))
						: RefreshIndicator(
							onRefresh: _loadSms,
							child: ListView.separated(
								itemCount: filteredItems.length,
								separatorBuilder: (_, _) => const Divider(height: 1),
								itemBuilder: (BuildContext context, int index) {
											final SmsDisplayItem item = filteredItems[index];
									return ListTile(
										onTap: () => Navigator.of(context).push(
										MaterialPageRoute<bool?>(
											builder: (_) => AddExpenseScreen(
												smsPayload: SmsPayload(
													sender: item.sms.sender,
													body: item.sms.body,
													receivedAt: item.sms.date,
												),
											),
										),
									),
										title: Text(
												item.sms.sender,
											maxLines: 1,
											overflow: TextOverflow.ellipsis,
										),
										subtitle: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: <Widget>[
												Text(
														item.sms.body,
													maxLines: 2,
													overflow: TextOverflow.ellipsis,
												),
													const SizedBox(height: 4),
													Text(
														item.tracked ? 'Tracked' : 'Untracked',
														style: TextStyle(
															color: item.tracked
																? Theme.of(context).colorScheme.secondary
																: Theme.of(context).colorScheme.error,
															fontWeight: FontWeight.w600,
														),
													),
												const SizedBox(height: 4),
												Text(
														_formatDate(item.sms.date),
													style: Theme.of(context).textTheme.labelMedium,
												),
											],
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

	List<SmsDisplayItem> _applyDateFilter(List<SmsDisplayItem> items) {
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

		return items.where((SmsDisplayItem item) {
			if (item.sms.date == null) {
				return false;
			}
			final DateTime itemDate = DateTime(
				item.sms.date!.year,
				item.sms.date!.month,
				item.sms.date!.day,
			);
			return itemDate == targetDate;
		}).toList(growable: false);
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

class SmsDisplayItem {
	const SmsDisplayItem({
		required this.sms,
		required this.hash,
		required this.tracked,
	});

	final SmsItem sms;
	final String hash;
	final bool tracked;
}

