import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';

class SmsService {
  SmsService({Telephony? telephony}) : _telephony = telephony ?? Telephony.instance;

  final Telephony _telephony;

  bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> requestPermissions() async {
    final bool? granted = await _telephony.requestPhoneAndSmsPermissions;
    return granted == true;
  }

  Future<List<SmsMessage>> readInboxMessages() {
    return _telephony.getInboxSms(
      columns: <SmsColumn>[SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: <OrderBy>[OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );
  }
}
