import 'package:flutter/material.dart';
import 'package:selavu/core/data/sms_repository.dart';

class DashboardScreen extends StatefulWidget {
	const DashboardScreen({super.key});

	@override
	State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
	final SmsRepository _repository = SmsRepository();

	List<SmsItem> _items = <SmsItem>[];
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
			final List<SmsItem> sms = await _repository.getInboxSms();
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

		if (_items.isEmpty) {
			return const Center(child: Text('No SMS messages found.'));
		}

		return RefreshIndicator(
			onRefresh: _loadSms,
			child: ListView.separated(
				itemCount: _items.length,
				separatorBuilder: (_, _) => const Divider(height: 1),
				itemBuilder: (BuildContext context, int index) {
					final SmsItem item = _items[index];
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
