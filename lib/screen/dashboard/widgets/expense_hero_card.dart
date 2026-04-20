import 'package:flutter/material.dart';

enum ExpenseRange {
  today,
  yesterday,
  past2Days,
  past3Days,
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
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: <Widget>[
        Container(
          width: double.infinity,
          height: 220,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            children: <Widget>[
              const Spacer(),
              Align(
                alignment: Alignment.bottomCenter,
                child: Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: '₹$monthText',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: '/M',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 12,
          child: Text(
            '₹',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 220,
                  color: scheme.onSurface.withOpacity(0.08),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Positioned(
          top: 48,
          right: 16,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.settings,
              color: scheme.onSurface,
            ),
          ),
        ),
        Positioned(
          top: 48,
          left: 24,
          child: Text(
            'This Month’s \nSpending',
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
          ),
        ),
        Positioned(
          bottom: -10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonHideUnderline(
                  child: DropdownButton<ExpenseRange>(
                    value: range,
                    dropdownColor: scheme.surface,
                    iconEnabledColor: scheme.onSecondaryContainer,
                    iconSize: 12,
                    icon: const Icon(Icons.arrow_drop_down, size: 12),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    isDense: true,
                    onChanged: (ExpenseRange? value) {
                      if (value == null) {
                        return;
                      }
                      onRangeChanged(value);
                    },
                    items: const <DropdownMenuItem<ExpenseRange>>[
                      DropdownMenuItem<ExpenseRange>(
                        value: ExpenseRange.today,
                        child: Text('Today'),
                      ),
                      DropdownMenuItem<ExpenseRange>(
                        value: ExpenseRange.yesterday,
                        child: Text('Yesterday'),
                      ),
                      DropdownMenuItem<ExpenseRange>(
                        value: ExpenseRange.past2Days,
                        child: Text('Past 2 days'),
                      ),
                      DropdownMenuItem<ExpenseRange>(
                        value: ExpenseRange.past3Days,
                        child: Text('Past 3 days'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '₹$rangeText',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
