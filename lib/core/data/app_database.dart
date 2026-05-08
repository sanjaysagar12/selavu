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
      version: 5,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE payment_methods ADD COLUMN icon TEXT');
          await db.execute('ALTER TABLE payment_methods ADD COLUMN color TEXT');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE transactions ADD COLUMN counterparty TEXT');
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE split_items ADD COLUMN person_number TEXT');
          await db.execute('ALTER TABLE loan_transactions ADD COLUMN person_number TEXT');
        }
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
  icon TEXT,
  color TEXT,
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
  counterparty TEXT,
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
  person_number TEXT,
  amount REAL NOT NULL CHECK (amount >= 0),
  settled BOOLEAN NOT NULL DEFAULT FALSE CHECK (settled IN (0, 1)),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (split_transaction_id) REFERENCES split_transactions(id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE loan_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id INTEGER,
  person_name TEXT NOT NULL,
  person_number TEXT,
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
      {
        'name': 'Food',
        'type': 'expense',
        'color': '#E76F51',
        'icon': 'restaurant',
      },
      {
        'name': 'Transport',
        'type': 'expense',
        'color': '#2A9D8F',
        'icon': 'directions_car',
      },
      {
        'name': 'Shopping',
        'type': 'expense',
        'color': '#8AB17D',
        'icon': 'shopping_bag',
      },
      {
        'name': 'Bills',
        'type': 'expense',
        'color': '#457B9D',
        'icon': 'receipt_long',
      },
      {'name': 'Rent', 'type': 'expense', 'color': '#1D3557', 'icon': 'home'},
      {
        'name': 'Entertainment',
        'type': 'expense',
        'color': '#EF476F',
        'icon': 'movie',
      },
      {
        'name': 'Health',
        'type': 'expense',
        'color': '#06D6A0',
        'icon': 'local_hospital',
      },
      {
        'name': 'Education',
        'type': 'expense',
        'color': '#118AB2',
        'icon': 'school',
      },
      {
        'name': 'Travel',
        'type': 'expense',
        'color': '#F77F00',
        'icon': 'flight_takeoff',
      },
      {
        'name': 'Other',
        'type': 'expense',
        'color': '#A8A8A8',
        'icon': 'more_horiz',
      },
    ];

    const List<Map<String, String>> incomeCategories = <Map<String, String>>[
      {'name': 'Salary', 'type': 'income', 'color': '#2EC4B6', 'icon': 'work'},
      {
        'name': 'Freelance',
        'type': 'income',
        'color': '#48CAE4',
        'icon': 'design_services',
      },
      {
        'name': 'Business',
        'type': 'income',
        'color': '#00B4D8',
        'icon': 'store',
      },
      {
        'name': 'Investment',
        'type': 'income',
        'color': '#0077B6',
        'icon': 'trending_up',
      },
      {
        'name': 'Other',
        'type': 'income',
        'color': '#577590',
        'icon': 'payments',
      },
    ];
    const List<Map<String, String>> paymentMethods = <Map<String, String>>[
      {'name': 'Cash', 'icon': 'payments', 'color': '#2A9D8F'},
      {'name': 'UPI', 'icon': 'qr_code', 'color': '#3A86FF'},
      {'name': 'Debit Card', 'icon': 'credit_card', 'color': '#118AB2'},
      {'name': 'Credit Card', 'icon': 'credit_card', 'color': '#8338EC'},
      {'name': 'Net Banking', 'icon': 'account_balance', 'color': '#457B9D'},
      {'name': 'Wallet', 'icon': 'account_balance_wallet', 'color': '#EF476F'},
      {'name': 'Bank Transfer', 'icon': 'swap_horiz', 'color': '#06D6A0'},
      {'name': 'Cheque', 'icon': 'request_page', 'color': '#F77F00'},
    ];

    for (final Map<String, String> category in expenseCategories) {
      batch.insert(
        'categories',
        category,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    for (final Map<String, String> category in incomeCategories) {
      batch.insert(
        'categories',
        category,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    for (final Map<String, String> method in paymentMethods) {
      batch.insert(
        'payment_methods',
        method,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    await batch.commit(noResult: true);
  }
}
