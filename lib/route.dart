import 'package:flutter/material.dart';

import 'package:selavu/screen/dashboard/dashboard_screen.dart';
import 'package:selavu/screen/splash/splash_screen.dart';

class AppRoutes {
	static const String dashboard = '/dashboard';
	static const String splash = '/splash';

	static String get initialRoute => dashboard;

	static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
				dashboard: (_) => const DashboardScreen(),
				splash: (_) => const SplashScreen(),
			};
}
