import 'package:flutter/material.dart';
import 'package:selavu/core/model/sms_payload.dart';

class SmsDetailsCard extends StatelessWidget {
  const SmsDetailsCard({super.key, required this.sms});

  final SmsPayload sms;

  @override
  Widget build(BuildContext context) {
    final DateTime? receivedAt = sms.receivedAt;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'SMS Data',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text('Sender: ${sms.sender}'),
          const SizedBox(height: 4),
          Text('Message: ${sms.body}'),
          if (receivedAt != null) ...<Widget>[
            const SizedBox(height: 4),
            Text('Received: ${receivedAt.toLocal()}'),
          ],
        ],
      ),
    );
  }
}
