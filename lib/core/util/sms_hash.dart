import 'dart:convert';

import 'package:crypto/crypto.dart';

String computeSmsHash({
  required String sender,
  required String body,
  required DateTime? receivedAt,
}) {
  final String timestamp = receivedAt?.millisecondsSinceEpoch.toString() ?? '';
  final String payload = '$sender|$body|$timestamp';
  return sha256.convert(utf8.encode(payload)).toString();
}
