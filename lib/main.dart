import 'package:another_telephony/telephony.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:selavu/core/model/sms_payload.dart';
import 'package:selavu/core/util/sms_parser.dart';

import 'package:selavu/route.dart';
import 'package:selavu/screen/transaction/add_transaction_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  final String? body = message.body;
  final String? sender = message.address;

  if (body != null && sender != null && SmsParser.isBankTransaction(sender, body)) {
    final double? amount = SmsParser.extractAmount(body);
    final bool isCredit = SmsParser.isCredit(body);
    
    if (!isCredit) {
      await _showNotification(sender, body, amount);
    }
  }
}

Future<void> _showNotification(String sender, String body, double? amount) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'sms_tracking_channel',
    'SMS Tracking',
    channelDescription: 'Notifications for bank transaction SMS',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    id: 0,
    title: 'Bank Transaction Detected',
    body: 'Spent ${amount?.toStringAsFixed(2) ?? "some amount"} at $sender. Tap to track.',
    notificationDetails: platformChannelSpecifics,
    payload: '$sender|$body|${DateTime.now().toIso8601String()}',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      final String? payload = response.payload;
      if (payload != null) {
        _handleSmsPayload(payload);
      }
    },
  );

  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    final String? payload =
        notificationAppLaunchDetails?.notificationResponse?.payload;
    if (payload != null) {
      // Delay to ensure navigator is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleSmsPayload(payload);
      });
    }
  }

  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void _handleSmsPayload(String payload) {
  final List<String> parts = payload.split('|');
  if (parts.length >= 3) {
    final String sender = parts[0];
    final String body = parts[1];
    final DateTime? date = DateTime.tryParse(parts[2]);

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          smsPayload: SmsPayload(
            sender: sender,
            body: body,
            receivedAt: date,
          ),
          initialType: SmsParser.isCredit(body)
              ? TransactionType.income
              : TransactionType.expense,
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const MethodChannel _channel = MethodChannel('com.example.selavu/sms');

  @override
  void initState() {
    super.initState();
    _initSmsListener();
    _checkPendingSms();
  }

  Future<void> _initSmsListener() async {
    final Telephony telephony = Telephony.instance;
    final bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;

    if (permissionsGranted == true) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          final String? body = message.body;
          final String? sender = message.address;
          if (body != null && sender != null && SmsParser.isBankTransaction(sender, body)) {
             if (!SmsParser.isCredit(body)) {
                _showNotification(sender, body, SmsParser.extractAmount(body));
             }
          }
        },
        onBackgroundMessage: backgroundMessageHandler,
      );
    }
  }

  Future<void> _checkPendingSms() async {
    try {
      final Map<dynamic, dynamic>? pending = await _channel.invokeMethod('getPendingSms');
      if (pending != null) {
        final String? sender = pending['sender'];
        final String? body = pending['body'];
        final String? receivedAtStr = pending['receivedAt'];
        
        if (sender != null && body != null) {
          final DateTime? date = receivedAtStr != null ? DateTime.tryParse(receivedAtStr) : null;
          
          // Wait for navigator to be ready
          Future.delayed(const Duration(milliseconds: 500), () {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => AddTransactionScreen(
                  smsPayload: SmsPayload(
                    sender: sender,
                    body: body,
                    receivedAt: date,
                  ),
                  initialType: SmsParser.isCredit(body)
                      ? TransactionType.income
                      : TransactionType.expense,
                ),
              ),
            );
          });
        }
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to get pending SMS: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Selavu',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.initialRoute,
      routes: AppRoutes.routes,
    );
  }
}
