import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_report_provider.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/utils/currency_formatter.dart';

class ExpenseReportScreen extends StatefulWidget {
  final ShopModel shop;
  const ExpenseReportScreen({super.key, required this.shop});

  @override
  State<ExpenseReportScreen> createState() => _ExpenseReportScreenState();
}

class _ExpenseReportScreenState extends State<ExpenseReportScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  final ScrollController _historyController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    _historyController.addListener(_onHistoryScroll);
  }

  void _loadData() async {
    final provider = Provider.of<ExpenseReportProvider>(context, listen: false);
    await provider.loadCategorySummary(widget.shop.id, _startDate, _endDate);
    await provider.loadExpensesHistory(widget.shop.id, refresh: true);
  }

  void _onHistoryScroll() {
    if (_historyController.position.pixels >= _historyController.position.maxScrollExtent - 200) {
      Provider.of<ExpenseReportProvider>(context, listen: false)
          .loadExpensesHistory(widget.shop.id);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseReportProvider>(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Expenses Report - ${widget.shop.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(onPressed: _pickDateRange, icon: const Icon(Icons.calendar_month_rounded, color: Colors.blue)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKPISection(provider),
              const SizedBox(height: 24),
              _buildCategorySummary(provider),
              const SizedBox(height: 24),
              _buildExpensesHistoryList(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPISection(ExpenseReportProvider provider) {
    if (provider.isLoadingCategory && provider.categorySummary.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final totalExpenses = provider.categorySummary.fold(0.0, (sum, item) => sum + item.totalAmount);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.pink.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Expenses', style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(totalExpenses, widget.shop.currency ?? 'TZS'),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.date_range, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySummary(ExpenseReportProvider provider) {
    if (provider.isLoadingCategory) return const Center(child: CircularProgressIndicator());
    if (provider.categorySummary.isEmpty) return const Text('No expenses in this period', style: TextStyle(color: Colors.grey));
    
    return _buildCard(
      title: 'Expenses by Category',
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: provider.categorySummary.length,
        separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100),
        itemBuilder: (_, i) {
          final item = provider.categorySummary[i];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade50,
              child: Icon(Icons.category, color: Colors.orange.shade400),
            ),
            title: Text(item.category, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Text(
              CurrencyFormatter.format(item.totalAmount, widget.shop.currency ?? 'TZS'),
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpensesHistoryList(ExpenseReportProvider provider) {
    return _buildCard(
      title: 'Expenses History',
      child: provider.expensesHistory.isEmpty && !provider.isLoadingHistory
          ? const Text('No expenses recorded', style: TextStyle(color: Colors.grey))
          : ListView.separated(
              controller: _historyController,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.expensesHistory.length + (provider.isLoadingHistory ? 1 : 0),
              separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100),
              itemBuilder: (_, i) {
                if (i == provider.expensesHistory.length) {
                  return const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()));
                }
                final doc = provider.expensesHistory[i];
                final data = doc.data();
                final date = (data['expenseDate'] as Timestamp).toDate();
                final amount = (data['amount'] as num).toDouble();
                final description = data['description'] as String;
                final category = data['category'] as String;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade50,
                    child: Icon(Icons.receipt_long, color: Colors.red.shade400),
                  ),
                  title: Text(description, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '$category • ${DateFormat('dd MMM yyyy').format(date)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  trailing: Text(
                    CurrencyFormatter.format(amount, widget.shop.currency ?? 'TZS'),
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                );
              },
            ),
    );
  }
}