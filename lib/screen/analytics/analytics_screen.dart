import 'package:flutter/material.dart';
import 'package:selavu/core/data/transaction_repository.dart';
import 'package:selavu/core/service/transaction_service.dart';
import 'package:selavu/core/util/ui_util.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final TransactionService _service = TransactionService();
  String _selectedRange = 'Month';
  String _selectedType = 'expense';
  
  bool _isLoading = true;
  double _total = 0;
  List<CategoryBreakdown> _categories = [];
  List<PaymentMethodBreakdown> _paymentMethods = [];

  final List<String> _ranges = ['Week', 'Month', '6 Months', 'Year'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day + 1);

    switch (_selectedRange) {
      case 'Week':
        start = end.subtract(const Duration(days: 7));
        break;
      case '6 Months':
        start = DateTime(now.year, now.month - 6, now.day);
        break;
      case 'Year':
        start = DateTime(now.year, 1, 1);
        break;
      case 'Month':
      default:
        start = DateTime(now.year, now.month, 1);
        break;
    }

    if (_selectedType == 'expense') {
      _total = await _service.getExpenseTotalBetween(start: start, end: end);
    } else {
      _total = await _service.getIncomeTotalBetween(start: start, end: end);
    }

    _categories = await _service.getCategoryBreakdown(type: _selectedType, start: start, end: end);
    _paymentMethods = await _service.getPaymentMethodBreakdown(type: _selectedType, start: start, end: end);

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Financial Insights', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(),
                        const SizedBox(height: 32),
                        _buildCategorySection(),
                        const SizedBox(height: 32),
                        _buildPaymentMethodSection(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Range Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _ranges.map((range) {
                final isSelected = _selectedRange == range;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(range),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedRange = range);
                        _loadData();
                      }
                    },
                    selectedColor: const Color(0xFFE8F5E9),
                    checkmarkColor: const Color(0xFF1B5E20),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF1B5E20) : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Type Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTypeBtn('Expense', 'expense'),
                  _buildTypeBtn('Income', 'income'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBtn(String label, String type) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedType = type);
          _loadData();
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          margin: const EdgeInsets.all(4),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? (type == 'expense' ? Colors.red[700] : Colors.green[700]) : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final color = _selectedType == 'expense' ? Colors.red[700] : Colors.green[700];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _selectedType == 'expense' 
            ? [const Color(0xFFFFEBEE), Colors.white]
            : [const Color(0xFFE8F5E9), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color!.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total ${_selectedType == 'expense' ? 'Spent' : 'Earned'}',
            style: TextStyle(color: color.withAlpha(180), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${_total.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                'Calculated for the selected $_selectedRange',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BY CATEGORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        if (_categories.isEmpty)
          _buildEmptyState('No transactions in this period')
        else
          ..._categories.map((cat) => _buildCategoryItem(cat)),
      ],
    );
  }

  Widget _buildCategoryItem(CategoryBreakdown cat) {
    final color = UIUtil.hexToColor(cat.color, defaultColor: Colors.teal);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                child: Icon(UIUtil.getIconData(cat.icon), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${(cat.percentage * 100).toStringAsFixed(1)}% of total', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              Text('₹${cat.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cat.percentage,
              backgroundColor: Colors.grey[200],
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BY PAYMENT METHOD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        if (_paymentMethods.isEmpty)
          _buildEmptyState('No method data available')
        else
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _paymentMethods.length,
              itemBuilder: (context, index) {
                final pm = _paymentMethods[index];
                final color = UIUtil.hexToColor(pm.color, defaultColor: Colors.blue);
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withAlpha(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(UIUtil.getIconData(pm.icon), size: 16, color: color),
                          const SizedBox(width: 6),
                          Expanded(child: Text(pm.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('₹${pm.total.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(20)),
      ),
      child: Column(
        children: [
          Icon(Icons.analytics_outlined, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }
}
