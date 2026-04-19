class SmsPayload {
  const SmsPayload({
    required this.sender,
    required this.body,
    required this.receivedAt,
  });

  final String sender;
  final String body;
  final DateTime? receivedAt;
}
