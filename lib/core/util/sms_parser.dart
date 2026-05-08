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
    'KVB',
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
    final String normalized = body.replaceAll('\n', ' ');

    // Pattern 1: Look for names after "from" or "to" or "for"
    // Use lookaheads for common separators like "on", "info", "via", "at", "debit", "credit"
    final RegExp fromRegex = RegExp(
      r'\bfrom\s+([A-Za-z0-9\s&@\-_]+?)(?=\s+(?:on|at|via|info|ref|upi|using|for|is|[\.]|:)|$)',
      caseSensitive: false,
    );
    final RegExp toRegex = RegExp(
      r'\bto\s+([A-Za-z0-9\s&@\-_]+?)(?=\s+(?:on|at|via|info|ref|upi|using|for|is|[\.]|:)|$)',
      caseSensitive: false,
    );
    final RegExp forRegex = RegExp(
      r'\bfor\s+([A-Za-z0-9\s&@\-_]+?)(?=\s+(?:on|at|via|info|ref|upi|using|for|is|debit|credit|[\.]|:)|$)',
      caseSensitive: false,
    );

    // Order of priority: 
    // 1. If credit, "from" is strongest
    // 2. If debit, "to" is strongest
    // 3. "for" as fallback for merchant names
    
    if (isCredit) {
      final match = fromRegex.firstMatch(normalized);
      if (match != null) return match.group(1)?.trim();
    } else {
      final match = toRegex.firstMatch(normalized);
      if (match != null) return match.group(1)?.trim();
    }

    // Fallbacks
    final forMatch = forRegex.firstMatch(normalized);
    if (forMatch != null) return forMatch.group(1)?.trim();

    // Last resort: try the other direction
    if (isCredit) {
      final match = toRegex.firstMatch(normalized);
      if (match != null) return match.group(1)?.trim();
    } else {
      final match = fromRegex.firstMatch(normalized);
      if (match != null) return match.group(1)?.trim();
    }

    return null;
  }
}
