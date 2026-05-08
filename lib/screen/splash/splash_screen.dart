import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:selavu/route.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleStartUp();
  }

  Future<void> _handleStartUp() async {
    // Artificial delay for splash feel
    await Future.delayed(const Duration(seconds: 2));

    // Check permissions
    final bool hasSms = await Permission.sms.isGranted;
    final bool hasContacts = await Permission.contacts.isGranted;

    if (mounted) {
      if (hasSms && hasContacts) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.requestPermission);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo or Placeholder
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withAlpha(60),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'SELAVU',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track. Save. Simplify.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
