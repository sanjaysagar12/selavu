import 'package:another_telephony/telephony.dart';
import 'package:selavu/core/service/sms_service.dart';

class SmsItem {
  const SmsItem({
    required this.sender,
    required this.body,
    required this.date,
  });

  final String sender;
  final String body;
  final DateTime? date;
}


class SmsRepository {
  SmsRepository({SmsService? service}) : _service = service ?? SmsService();

  final SmsService _service;

  Future<List<SmsItem>> getInboxSms() async {
    if (!_service.isAndroid) {
      throw Exception('SMS reading is only supported on Android devices.');
    }

    final bool hasPermission = await _service.requestPermissions();
    if (!hasPermission) {
      throw Exception('Permission denied. Please allow SMS permission in settings.');
    }

    final List<SmsMessage> messages = await _service.readInboxMessages();

    return messages
        .map(
          (SmsMessage message) => SmsItem(
            sender: message.address?.trim().isNotEmpty == true
                ? message.address!.trim()
                : 'Unknown sender',
            body: message.body?.trim().isNotEmpty == true ? message.body!.trim() : '(Empty)',
            date: message.date == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(message.date!),
          ),
        )
        .toList(growable: false);
  }
}
