class SmsParser {
  static const List<String> bankSenderHints = <String>[
    'HDFC',
    'SBI',
    'ICICI',
    'AXIS',
    'KOTAK',
    'IDFC',
    'YESBNK',
    'PNB',
    'CANBNK',
    'BOB',
    'CITI',
    'INDUS',
  ];

  static const List<String> transactionKeywords = <String>[
    'debited',
    'credited',
    'debit',
    'credit',
    'withdrawn',
    'withdrawal',
    'spent',
    'txn',
    'transaction',
    'a/c',
    'account',
    'balance',
    'upi',
    'neft',
    'imps',
    'rtgs',
  ];

  static bool isBankTransaction(String sender, String body) {
    final String normalizedSender = sender.toUpperCase();
    final String normalizedBody = body.toLowerCase();

    final bool senderLooksLikeBank =
        bankSenderHints.any((String hint) => normalizedSender.contains(hint));
    final bool containsTransactionText =
        transactionKeywords.any((String keyword) => normalizedBody.contains(keyword));
    final bool containsAmount =
        normalizedBody.contains('inr') ||
        normalizedBody.contains('rs.') ||
        normalizedBody.contains('rs ');

    return containsTransactionText && (senderLooksLikeBank || containsAmount);
  }

  static double? extractAmount(String body) {
    final RegExp rupeePattern = RegExp(
      r'(?:inr|rs\.?|rs)\s*([0-9,]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    final RegExp reversePattern = RegExp(
      r'([0-9,]+(?:\.[0-9]{1,2})?)\s*(?:inr|rs\.?|rs)',
      caseSensitive: false,
    );

    final RegExpMatch? match =
        rupeePattern.firstMatch(body) ?? reversePattern.firstMatch(body);
    if (match == null) {
      return null;
    }

    final String raw = match.group(1) ?? '';
    if (raw.isEmpty) {
      return null;
    }

    final String normalized = raw.replaceAll(',', '');
    return double.tryParse(normalized);
  }

  static bool isCredit(String body) {
    final String normalized = body.toLowerCase();
    const List<String> creditKeywords = <String>[
      'credited',
      'credit',
      'received',
      'deposited',
      'deposit',
      'cr',
    ];
    const List<String> debitKeywords = <String>[
      'debited',
      'debit',
      'spent',
      'withdrawn',
      'withdraw',
      'purchase',
      'dr',
    ];

    for (final String keyword in creditKeywords) {
      if (normalized.contains(keyword)) {
        return true;
      }
    }

    for (final String keyword in debitKeywords) {
      if (normalized.contains(keyword)) {
        return false;
      }
    }

    return false;
  }

  static String? extractCounterparty(String body, bool isCredit) {
    final RegExp creditRegex = RegExp(
      r'(?:received|credited|transfer.*)?\s+from\s+([A-Za-z0-9\s&@\-_]+?)(?=\s+(?:on|via|ref|upi|using|info|for|[\.]+)|$|info)',
      caseSensitive: false,
    );
    final RegExp debitRegex = RegExp(
      r'(?:paid|sent|transfer.*|debited.*)?\s+to\s+([A-Za-z0-9\s&@\-_]+?)(?=\s+(?:on|via|ref|upi|using|info|for|[\.]+)|$|info)',
      caseSensitive: false,
    );
    final RegExp forRegex = RegExp(
      r'for\s+([A-Za-z0-9\s&@\-_]+?)(?=\s+(?:debit|credit|is|on|via|ref|upi|using|info|for|[\.]+)|$|info)',
      caseSensitive: false,
    );

    final RegExpMatch? forMatch = forRegex.firstMatch(body);
    if (forMatch != null) {
      return forMatch.group(1)?.trim();
    }

    if (isCredit) {
      final RegExpMatch? match = creditRegex.firstMatch(body);
      return match?.group(1)?.trim();
    } else {
      final RegExpMatch? match = debitRegex.firstMatch(body);
      return match?.group(1)?.trim();
    }
  }
}
