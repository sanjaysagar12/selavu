import 'package:flutter/material.dart';

import 'package:selavu/screen/dashboard/dashboard_screen.dart';
import 'package:selavu/screen/splash/splash_screen.dart';
import 'package:selavu/screen/transaction/add_transaction_screen.dart';

class AppRoutes {
	static const String dashboard = '/dashboard';
	static const String splash = '/splash';
	static const String addTransaction = '/add-transaction';

	static String get initialRoute => dashboard;

	static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
				dashboard: (_) => const DashboardScreen(),
				splash: (_) => const SplashScreen(),
				addTransaction: (BuildContext context) {
					final TransactionType? type =
							ModalRoute.of(context)?.settings.arguments as TransactionType?;
					return AddTransactionScreen(initialType: type ?? TransactionType.expense);
				},
			};
}
