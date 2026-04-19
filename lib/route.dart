import 'package:flutter/material.dart';

import 'package:selavu/screen/dashboard/dashboard_screen.dart';
import 'package:selavu/screen/splash/splash_screen.dart';
import 'package:selavu/screen/transaction/add_expense_screen.dart';
import 'package:selavu/screen/transaction/add_income_screen.dart';

class AppRoutes {
	static const String dashboard = '/dashboard';
	static const String splash = '/splash';
	static const String addExpense = '/add-expense';
	static const String addIncome = '/add-income';

	static String get initialRoute => dashboard;

	static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
				dashboard: (_) => const DashboardScreen(),
				splash: (_) => const SplashScreen(),
				addExpense: (_) => const AddExpenseScreen(),
				addIncome: (_) => const AddIncomeScreen(),
			};
}
