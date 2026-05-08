import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:selavu/route.dart';

class PermissionRequestScreen extends StatefulWidget {
  const PermissionRequestScreen({super.key});

  @override
  State<PermissionRequestScreen> createState() => _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> {
  bool _isRequesting = false;

  Future<void> _requestPermissions() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);

    try {
      debugPrint('Requesting permissions...');
      
      // Check current status first
      final initialSmsStatus = await Permission.sms.status;
      debugPrint('Initial SMS Status: $initialSmsStatus');

      // Add a tiny delay to ensure UI is stable
      await Future.delayed(const Duration(milliseconds: 300));

      // Request SMS
      final smsStatus = await Permission.sms.request();
      debugPrint('Final SMS Status: $smsStatus');
      
      // Request Contacts
      await Permission.contacts.request();
      debugPrint('Final Contacts Status check completed');

      setState(() => _isRequesting = false);

      if (smsStatus.isGranted) {
        debugPrint('SMS Granted! Navigating to dashboard...');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
        }
      } else if (smsStatus.isPermanentlyDenied) {
        debugPrint('SMS Permanently Denied. Showing settings dialog...');
        if (mounted) {
          _showSettingsDialog();
        }
      } else {
        debugPrint('SMS Denied (normal). Status: $smsStatus');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permission Status: $smsStatus. Please allow SMS to continue.'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'RETRY',
                textColor: Colors.white,
                onPressed: _requestPermissions,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in _requestPermissions: $e');
      setState(() => _isRequesting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Denied'),
        content: const Text(
            'SMS permission is required to automatically track your expenses. Please enable it in the app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('SETTINGS'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            children: [
              const Spacer(),
              // Hero Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security_outlined,
                  size: 60,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Your Privacy, Guaranteed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B1B1B),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Selavu is a 100% offline application. Everything you see—your transactions, contacts, and SMS data—stays encrypted on your device and never touches a server.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              // Permission List
              _buildPermissionItem(
                icon: Icons.sms_outlined,
                title: 'SMS Access',
                description: 'To automatically detect and log your transaction alerts.',
              ),
              const SizedBox(height: 24),
              _buildPermissionItem(
                icon: Icons.contacts_outlined,
                title: 'Contacts Access',
                description: 'To easily split bills with your friends and family.',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isRequesting ? null : _requestPermissions,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isRequesting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Allow & Proceed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blueGrey, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B1B1B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
