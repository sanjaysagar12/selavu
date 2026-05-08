import 'package:flutter/material.dart';
import 'package:selavu/screen/transaction/add_transaction_screen.dart';

class TransactionTypeSelector extends StatelessWidget {
  const TransactionTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  final TransactionType selectedType;
  final ValueChanged<TransactionType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final isExpense = selectedType == TransactionType.expense;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _TypeButton(
              label: 'Spend',
              isSelected: isExpense,
              color: const Color(0xFF1B5E20),
              icon: Icons.check,
              onTap: () => onTypeChanged(TransactionType.expense),
            ),
          ),
          Container(
            height: 30,
            width: 1,
            color: Colors.grey.withAlpha(100),
          ),
          Expanded(
            child: _TypeButton(
              label: 'Income',
              isSelected: !isExpense,
              color: const Color(0xFF1B5E20),
              icon: Icons.check,
              onTap: () => onTypeChanged(TransactionType.income),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExtraTypeSelector extends StatelessWidget {
  const ExtraTypeSelector({
    super.key,
    required this.transactionType,
    required this.selectedExtraType,
    required this.onExtraTypeChanged,
  });

  final TransactionType transactionType;
  final ExtraType selectedExtraType;
  final ValueChanged<ExtraType> onExtraTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(30),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          if (transactionType == TransactionType.expense)
            Expanded(
              child: _ExtraButton(
                label: 'SPLIT',
                isSelected: selectedExtraType == ExtraType.split,
                onTap: () => onExtraTypeChanged(ExtraType.split),
              ),
            ),
          Expanded(
            child: _ExtraButton(
              label: 'LOAN',
              isSelected: selectedExtraType == ExtraType.loan,
              onTap: () => onExtraTypeChanged(ExtraType.loan),
            ),
          ),
          Expanded(
            child: _ExtraButton(
              label: 'NONE',
              isSelected: selectedExtraType == ExtraType.none,
              onTap: () => onExtraTypeChanged(ExtraType.none),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtraButton extends StatelessWidget {
  const _ExtraButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
