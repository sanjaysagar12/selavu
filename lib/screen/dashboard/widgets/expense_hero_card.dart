import 'package:flutter/material.dart';

enum ExpenseRange {
  today,
  past2Days,
  past4Days,
  week,
}

class ExpenseHeroCard extends StatelessWidget {
  const ExpenseHeroCard({
    super.key,
    required this.monthTotal,
    required this.periodTotal,
    required this.range,
    required this.onRangeChanged,
  });

  final double monthTotal;
  final double periodTotal;
  final ExpenseRange range;
  final ValueChanged<ExpenseRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final String monthText = monthTotal.toStringAsFixed(2);
    final String rangeText = periodTotal.toStringAsFixed(2);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Spending',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white, size: 12),
                    const SizedBox(width: 6),
                    Text(
                      _getRangeLabel(range),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹$monthText',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildMiniStat('Period Total', '₹$rangeText', Icons.trending_up),
              const SizedBox(width: 24),
              _buildMiniStat('Avg / Day', '₹${(monthTotal / 30).toStringAsFixed(0)}', Icons.analytics),
            ],
          ),
          const SizedBox(height: 20),
          _buildRangeSelector(),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white54, size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRangeSelector() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(40),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ExpenseRange.values.map((r) {
          final bool isSelected = r == range;
          return Expanded(
            child: GestureDetector(
              onTap: () => onRangeChanged(r),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getRangeLabel(r),
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF1B5E20) : Colors.white70,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getRangeLabel(ExpenseRange range) {
    switch (range) {
      case ExpenseRange.today: return 'Today';
      case ExpenseRange.past2Days: return '2 Days';
      case ExpenseRange.past4Days: return '4 Days';
      case ExpenseRange.week: return '1 Week';
    }
  }
}
