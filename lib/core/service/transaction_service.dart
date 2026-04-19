import 'package:selavu/core/data/transaction_repository.dart';

class SplitItemInput {
  const SplitItemInput({
    required this.personName,
    required this.amount,
    required this.isPayer,
    required this.settled,
  });

  final String personName;
  final double amount;
  final bool isPayer;
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
    required this.loanType,
    required this.principalAmount,
    required this.outstandingAmount,
    required this.status,
    this.note,
  });

  final String personName;
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

  Future<Set<String>> getTrackedSmsHashes(List<String> hashes) {
    return _repository.getExistingSmsHashes(hashes);
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
              'amount': item.amount,
              'is_payer': item.isPayer ? 1 : 0,
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
    String? note,
  }) {
    _validateAmount(amount);
    return _repository.insertTransaction(
      type: 'income',
      amount: amount,
      categoryId: categoryId,
      paymentMethodId: paymentMethodId,
      note: note,
    );
  }

  void _validateAmount(double amount) {
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }
  }
}
