import 'package:selavu/core/data/transaction_repository.dart';

class SplitItemInput {
  const SplitItemInput({
    required this.personName,
    this.personNumber,
    required this.amount,
    required this.settled,
  });

  final String personName;
  final String? personNumber;
  final double amount;
  final bool settled;
}

class SplitTransactionInput {
  const SplitTransactionInput({
    required this.mode,
    required this.totalAmount,
    required this.items,
  });

  final String mode;
  final double totalAmount;
  final List<SplitItemInput> items;
}

class LoanTransactionInput {
  const LoanTransactionInput({
    required this.personName,
    this.personNumber,
    required this.loanType,
    required this.principalAmount,
    required this.outstandingAmount,
    required this.status,
    this.note,
  });

  final String personName;
  final String? personNumber;
  final String loanType;
  final double principalAmount;
  final double outstandingAmount;
  final String status;
  final String? note;
}

class TransactionService {
  TransactionService({TransactionRepository? repository})
    : _repository = repository ?? TransactionRepository();

  final TransactionRepository _repository;

  Future<List<Category>> getExpenseCategories() {
    return _repository.getCategoriesByTypes(<String>['expense', 'both']);
  }

  Future<List<Category>> getIncomeCategories() {
    return _repository.getCategoriesByTypes(<String>['income', 'both']);
  }

  Future<List<PaymentMethod>> getPaymentMethods() {
    return _repository.getPaymentMethods();
  }

  Future<int> addPaymentMethod(String name) {
    return _repository.addPaymentMethod(name);
  }

  Future<List<TransactionItem>> getTransactions() {
    return _repository.getTransactions();
  }

  Future<List<SplitItemDetail>> getSplitItemsForTransaction(int transactionId) {
    return _repository.getSplitItemsByTransactionId(transactionId);
  }

  Future<Set<String>> getTrackedSmsHashes(List<String> hashes) {
    return _repository.getExistingSmsHashes(hashes);
  }

  Future<double> getExpenseTotalBetween({
    required DateTime start,
    required DateTime end,
  }) {
    return _repository.getExpenseTotalBetween(start: start, end: end);
  }

  Future<double> getTodayExpenseTotal() {
    final DateTime now = DateTime.now();
    final DateTime start = DateTime(now.year, now.month, now.day);
    final DateTime end = start.add(const Duration(days: 1));
    return _repository.getExpenseTotalBetween(start: start, end: end);
  }

  Future<double> getMonthExpenseTotal() {
    final DateTime now = DateTime.now();
    final DateTime start = DateTime(now.year, now.month, 1);
    final DateTime end = DateTime(now.year, now.month + 1, 1);
    return _repository.getExpenseTotalBetween(start: start, end: end);
  }

  Future<int> updateTransaction({
    required int id,
    required String type,
    required double amount,
    int? categoryId,
    int? paymentMethodId,
    String? counterparty,
    String? note,
  }) {
    _validateAmount(amount);
    return _repository.updateTransaction(
      id: id,
      type: type,
      amount: amount,
      categoryId: categoryId,
      paymentMethodId: paymentMethodId,
      counterparty: counterparty,
      note: note,
    );
  }

  Future<int> addExpense({required double amount, String? note}) {
    _validateAmount(amount);
    return _repository.insertTransaction(
      type: 'expense',
      amount: amount,
      note: note,
    );
  }

  Future<void> addExpenseWithExtras({
    required double amount,
    int? categoryId,
    int? paymentMethodId,
    String? counterparty,
    String? note,
    String? smsHash,
    String? smsSender,
    String? smsBody,
    DateTime? smsReceivedAt,
    SplitTransactionInput? split,
    LoanTransactionInput? loan,
  }) async {
    _validateAmount(amount);

    final int transactionId = await _repository.insertTransaction(
      type: 'expense',
      amount: amount,
      categoryId: categoryId,
      paymentMethodId: paymentMethodId,
      counterparty: counterparty,
      note: note,
      smsHash: smsHash,
      smsSender: smsSender,
      smsBody: smsBody,
      smsReceivedAt: smsReceivedAt,
    );

    if (split != null) {
      final int splitId = await _repository.insertSplitTransaction(
        transactionId: transactionId,
        splitMode: split.mode,
        totalAmount: split.totalAmount,
      );

      final List<Map<String, Object?>> items = split.items
          .map(
            (SplitItemInput item) => <String, Object?>{
              'person_name': item.personName,
              'person_number': item.personNumber,
              'amount': item.amount,
              'settled': item.settled ? 1 : 0,
            },
          )
          .toList(growable: false);

      if (items.isNotEmpty) {
        await _repository.insertSplitItems(
          splitTransactionId: splitId,
          items: items,
        );
      }
    }

    if (loan != null) {
      await _repository.insertLoanTransaction(
        transactionId: transactionId,
        personName: loan.personName,
        personNumber: loan.personNumber,
        loanType: loan.loanType,
        principalAmount: loan.principalAmount,
        outstandingAmount: loan.outstandingAmount,
        note: loan.note,
        status: loan.status,
      );
    }
  }

  Future<int> addIncome({required double amount, String? note}) {
    _validateAmount(amount);
    return _repository.insertTransaction(
      type: 'income',
      amount: amount,
      note: note,
    );
  }

  Future<int> addIncomeWithDetails({
    required double amount,
    int? categoryId,
    int? paymentMethodId,
    String? counterparty,
    String? note,
    String? smsHash,
    String? smsSender,
    String? smsBody,
    DateTime? smsReceivedAt,
  }) {
    _validateAmount(amount);
    return _repository.insertTransaction(
      type: 'income',
      amount: amount,
      categoryId: categoryId,
      paymentMethodId: paymentMethodId,
      counterparty: counterparty,
      note: note,
      smsHash: smsHash,
      smsSender: smsSender,
      smsBody: smsBody,
      smsReceivedAt: smsReceivedAt,
    );
  }

  Future<int> deleteTransaction(int id) {
    return _repository.deleteTransaction(id);
  }

  // --- Category Management ---
  Future<List<Category>> getAllCategories() => _repository.getAllCategories();
  Future<int> addCategory({required String name, required String type, String? icon, String? color}) => _repository.insertCategory(name, type, icon, color);
  Future<int> updateCategory({required int id, required String name, required String type, String? icon, String? color}) => _repository.updateCategory(id, name, type, icon, color);
  Future<int> deleteCategory(int id) => _repository.deleteCategory(id);

  // --- Payment Method Management ---
  Future<int> addPaymentMethodWithDetails({required String name, String? icon, String? color}) => _repository.insertPaymentMethod(name, icon, color);
  Future<int> updatePaymentMethod({required int id, required String name, String? icon, String? color}) => _repository.updatePaymentMethod(id, name, icon, color);
  Future<int> deletePaymentMethod(int id) => _repository.deletePaymentMethod(id);

  void _validateAmount(double amount) {
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }
  }
}
