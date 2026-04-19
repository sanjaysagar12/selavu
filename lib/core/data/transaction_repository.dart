import 'package:sqflite/sqflite.dart';

import 'package:selavu/core/data/app_database.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.type,
  });

  final int id;
  final String name;
  final String type;
}

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;
}

class TransactionItem {
  const TransactionItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.note,
    required this.transactionDate,
    required this.categoryName,
    required this.paymentMethodName,
    required this.categoryId,
    required this.paymentMethodId,
    required this.smsHash,
    required this.smsSender,
    required this.smsBody,
    required this.smsReceivedAt,
  });

  final int id;
  final String type;
  final double amount;
  final String? note;
  final DateTime? transactionDate;
  final String? categoryName;
  final String? paymentMethodName;
  final int? categoryId;
  final int? paymentMethodId;
  final String? smsHash;
  final String? smsSender;
  final String? smsBody;
  final DateTime? smsReceivedAt;
}

class TransactionRepository {
  TransactionRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<Category>> getCategoriesByTypes(List<String> types) async {
    final Database db = await _database.database;
    final String placeholders = List<String>.filled(types.length, '?').join(',');

    final List<Map<String, Object?>> rows = await db.query(
      'categories',
      where: 'type IN ($placeholders)',
      whereArgs: types,
      orderBy: 'name ASC',
    );

    return rows
        .map(
          (Map<String, Object?> row) => Category(
            id: row['id'] as int,
            name: row['name'] as String,
            type: row['type'] as String,
          ),
        )
        .toList(growable: false);
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.query(
      'payment_methods',
      orderBy: 'name ASC',
    );

    return rows
        .map(
          (Map<String, Object?> row) => PaymentMethod(
            id: row['id'] as int,
            name: row['name'] as String,
          ),
        )
        .toList(growable: false);
  }

  Future<int> addPaymentMethod(String name) async {
    final Database db = await _database.database;
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Payment method name cannot be empty.');
    }

    final List<Map<String, Object?>> existing = await db.query(
      'payment_methods',
      columns: <String>['id'],
      where: 'name = ?',
      whereArgs: <Object?>[trimmed],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    return db.insert('payment_methods', <String, Object?>{'name': trimmed});
  }

  Future<Set<String>> getExistingSmsHashes(List<String> hashes) async {
    if (hashes.isEmpty) {
      return <String>{};
    }

    final Database db = await _database.database;
    final String placeholders = List<String>.filled(hashes.length, '?').join(',');

    final List<Map<String, Object?>> rows = await db.query(
      'transactions',
      columns: <String>['sms_hash'],
      where: 'sms_hash IN ($placeholders)',
      whereArgs: hashes,
    );

    return rows
        .map((Map<String, Object?> row) => row['sms_hash'] as String)
        .toSet();
  }

  Future<List<TransactionItem>> getTransactions() async {
    final Database db = await _database.database;
    final List<Map<String, Object?>> rows = await db.rawQuery('''
SELECT
  t.id,
  t.type,
  t.amount,
  t.note,
  t.transaction_date,
  t.category_id,
  t.payment_method_id,
  t.sms_hash,
  t.sms_sender,
  t.sms_body,
  t.sms_received_at,
  c.name AS category_name,
  pm.name AS payment_method_name
FROM transactions t
LEFT JOIN categories c ON c.id = t.category_id
LEFT JOIN payment_methods pm ON pm.id = t.payment_method_id
ORDER BY t.transaction_date DESC
''');

    return rows
        .map(
          (Map<String, Object?> row) => TransactionItem(
            id: row['id'] as int,
            type: row['type'] as String,
            amount: (row['amount'] as num).toDouble(),
            note: row['note'] as String?,
            transactionDate: row['transaction_date'] == null
                ? null
                : DateTime.tryParse(row['transaction_date'] as String),
            categoryId: row['category_id'] as int?,
            paymentMethodId: row['payment_method_id'] as int?,
            smsHash: row['sms_hash'] as String?,
            smsSender: row['sms_sender'] as String?,
            smsBody: row['sms_body'] as String?,
            smsReceivedAt: row['sms_received_at'] == null
                ? null
                : DateTime.tryParse(row['sms_received_at'] as String),
            categoryName: row['category_name'] as String?,
            paymentMethodName: row['payment_method_name'] as String?,
          ),
        )
        .toList(growable: false);
  }

  Future<int> updateTransaction({
    required int id,
    required String type,
    required double amount,
    int? categoryId,
    int? paymentMethodId,
    String? note,
  }) async {
    final Database db = await _database.database;

    return db.update(
      'transactions',
      <String, Object?>{
        'type': type,
        'amount': amount,
        'category_id': categoryId,
        'payment_method_id': paymentMethodId,
        'note': note,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<int> insertTransaction({
    required String type,
    required double amount,
    int? categoryId,
    int? paymentMethodId,
    String? note,
    DateTime? transactionDate,
    String? smsHash,
    String? smsSender,
    String? smsBody,
    DateTime? smsReceivedAt,
  }) async {
    final Database db = await _database.database;

    final Map<String, Object?> values = <String, Object?>{
      'type': type,
      'amount': amount,
      'category_id': categoryId,
      'payment_method_id': paymentMethodId,
      'note': note,
      'transaction_date': (transactionDate ?? DateTime.now()).toIso8601String(),
      'sms_hash': smsHash,
      'sms_sender': smsSender,
      'sms_body': smsBody,
      'sms_received_at': smsReceivedAt?.toIso8601String(),
    };

    return db.insert(
      'transactions',
      values,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> insertSplitTransaction({
    required int transactionId,
    required String splitMode,
    required double totalAmount,
  }) async {
    final Database db = await _database.database;
    return db.insert('split_transactions', <String, Object?>{
      'transaction_id': transactionId,
      'split_mode': splitMode,
      'total_amount': totalAmount,
    });
  }

  Future<void> insertSplitItems({
    required int splitTransactionId,
    required List<Map<String, Object?>> items,
  }) async {
    final Database db = await _database.database;
    final Batch batch = db.batch();

    for (final Map<String, Object?> item in items) {
      final Map<String, Object?> payload = <String, Object?>{
        'split_transaction_id': splitTransactionId,
        ...item,
      };
      batch.insert('split_items', payload);
    }

    await batch.commit(noResult: true);
  }

  Future<int> insertLoanTransaction({
    required int? transactionId,
    required String personName,
    required String loanType,
    required double principalAmount,
    required double outstandingAmount,
    String? note,
    String status = 'open',
  }) async {
    final Database db = await _database.database;
    return db.insert('loan_transactions', <String, Object?>{
      'transaction_id': transactionId,
      'person_name': personName,
      'loan_type': loanType,
      'principal_amount': principalAmount,
      'outstanding_amount': outstandingAmount,
      'note': note,
      'status': status,
    });
  }
}
