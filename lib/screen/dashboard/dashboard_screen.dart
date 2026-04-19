import 'package:flutter/material.dart';
import 'package:selavu/core/data/sms_repository.dart';
import 'package:selavu/route.dart';

class DashboardScreen extends StatefulWidget {
	const DashboardScreen({super.key});

	@override
	State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
	final SmsRepository _repository = SmsRepository();
	List<SmsItem> _items = <SmsItem>[];
	DateFilter _dateFilter = DateFilter.all;
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
			setState(() {
				_items = sms;
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

		final List<SmsItem> filteredItems = _applyDateFilter(_items);

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
				Expanded(
					child: filteredItems.isEmpty
						? const Center(child: Text('No bank credit/debit SMS found.'))
						: RefreshIndicator(
							onRefresh: _loadSms,
							child: ListView.separated(
								itemCount: filteredItems.length,
								separatorBuilder: (_, _) => const Divider(height: 1),
								itemBuilder: (BuildContext context, int index) {
									final SmsItem item = filteredItems[index];
									return ListTile(
										title: Text(
											item.sender,
											maxLines: 1,
											overflow: TextOverflow.ellipsis,
										),
										subtitle: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: <Widget>[
												Text(
													item.body,
													maxLines: 2,
													overflow: TextOverflow.ellipsis,
												),
												const SizedBox(height: 4),
												Text(
													_formatDate(item.date),
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

	List<SmsItem> _applyDateFilter(List<SmsItem> items) {
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

		return items.where((SmsItem item) {
			if (item.date == null) {
				return false;
			}
			final DateTime itemDate = DateTime(item.date!.year, item.date!.month, item.date!.day);
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

