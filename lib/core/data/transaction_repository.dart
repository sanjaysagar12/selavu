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
