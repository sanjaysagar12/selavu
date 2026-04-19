import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String dbPath = await getDatabasesPath();
    final String fullPath = path.join(dbPath, 'selavu.db');

    return openDatabase(
      fullPath,
      version: 1,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int version) async {
        await _createTables(db);
        await _seedInitialData(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  type TEXT NOT NULL CHECK (type IN ('expense', 'income', 'both')),
  icon TEXT,
  color TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
''');

    await db.execute('''
CREATE TABLE payment_methods (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
''');

    await db.execute('''
CREATE TABLE transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL CHECK (type IN ('expense', 'income')),
  amount REAL NOT NULL CHECK (amount > 0),
  category_id INTEGER,
  payment_method_id INTEGER,
  note TEXT,
  transaction_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  sms_hash TEXT UNIQUE,
  sms_sender TEXT,
  sms_body TEXT,
  sms_received_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories(id),
  FOREIGN KEY (payment_method_id) REFERENCES payment_methods(id)
)
''');

    await db.execute('''
CREATE TABLE split_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id INTEGER NOT NULL,
  split_mode TEXT NOT NULL CHECK (split_mode IN ('equal', 'exact')),
  total_amount REAL NOT NULL CHECK (total_amount > 0),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE split_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  split_transaction_id INTEGER NOT NULL,
  person_name TEXT NOT NULL,
  amount REAL NOT NULL CHECK (amount >= 0),
  is_payer INTEGER NOT NULL DEFAULT 0,
  settled INTEGER NOT NULL DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (split_transaction_id) REFERENCES split_transactions(id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE loan_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id INTEGER,
  person_name TEXT NOT NULL,
  loan_type TEXT NOT NULL CHECK (loan_type IN ('lend', 'borrow')),
  principal_amount REAL NOT NULL CHECK (principal_amount > 0),
  outstanding_amount REAL NOT NULL CHECK (outstanding_amount >= 0),
  note TEXT,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'partial', 'closed')),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE SET NULL
)
''');
  }

  Future<void> _seedInitialData(Database db) async {
    final Batch batch = db.batch();

    const List<Map<String, String>> expenseCategories = <Map<String, String>>[
      {'name': 'Food & Dining', 'type': 'expense'},
      {'name': 'Groceries', 'type': 'expense'},
      {'name': 'Transport', 'type': 'expense'},
      {'name': 'Fuel', 'type': 'expense'},
      {'name': 'Shopping', 'type': 'expense'},
      {'name': 'Bills & Utilities', 'type': 'expense'},
      {'name': 'Rent', 'type': 'expense'},
      {'name': 'Subscriptions', 'type': 'expense'},
      {'name': 'Entertainment', 'type': 'expense'},
      {'name': 'Health & Medical', 'type': 'expense'},
      {'name': 'Education', 'type': 'expense'},
      {'name': 'Travel', 'type': 'expense'},
      {'name': 'Personal Care', 'type': 'expense'},
      {'name': 'Gifts & Donations', 'type': 'expense'},
      {'name': 'Insurance', 'type': 'expense'},
      {'name': 'Taxes', 'type': 'expense'},
      {'name': 'Pets', 'type': 'expense'},
      {'name': 'Miscellaneous', 'type': 'expense'},
    ];

    const List<Map<String, String>> incomeCategories = <Map<String, String>>[
      {'name': 'Salary', 'type': 'income'},
      {'name': 'Freelance', 'type': 'income'},
      {'name': 'Business', 'type': 'income'},
      {'name': 'Investments', 'type': 'income'},
      {'name': 'Rental Income', 'type': 'income'},
      {'name': 'Interest', 'type': 'income'},
      {'name': 'Refunds', 'type': 'income'},
      {'name': 'Gifts Received', 'type': 'income'},
      {'name': 'Other Income', 'type': 'income'},
    ];

    const List<String> paymentMethods = <String>[
      'Cash',
      'UPI',
      'Debit Card',
      'Credit Card',
      'Net Banking',
      'Wallet',
      'Bank Transfer',
      'Cheque',
    ];

    for (final Map<String, String> category in expenseCategories) {
      batch.insert('categories', category);
    }

    for (final Map<String, String> category in incomeCategories) {
      batch.insert('categories', category);
    }

    for (final String method in paymentMethods) {
      batch.insert('payment_methods', <String, Object?>{'name': method});
    }

    await batch.commit(noResult: true);
  }
}
