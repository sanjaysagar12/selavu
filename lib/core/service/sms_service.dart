import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsService {
  SmsService({Telephony? telephony}) : _telephony = telephony ?? Telephony.instance;

  final Telephony _telephony;

  bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> requestPermissions() async {
    // We use permission_handler instead of telephony.requestPhoneAndSmsPermissions
    // to avoid the "Reply already submitted" crash in the telephony plugin.
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<List<SmsMessage>> readInboxMessages() {
    return _telephony.getInboxSms(
      columns: <SmsColumn>[SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: <OrderBy>[OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );
  }
}
