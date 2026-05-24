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
      appBar: AppBar(
        title: Text('Expenses Report - ${widget.shop.name}'),
        actions: [
          IconButton(onPressed: _pickDateRange, icon: const Icon(Icons.calendar_today)),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Expenses', style: TextStyle(fontSize: 16)),
                Text(
                  CurrencyFormatter.format(totalExpenses, widget.shop.currency ?? 'TZS'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySummary(ExpenseReportProvider provider) {
    if (provider.isLoadingCategory) return const Center(child: CircularProgressIndicator());
    if (provider.categorySummary.isEmpty) return const Text('No expenses in this period');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Expenses by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.categorySummary.length,
              itemBuilder: (_, i) {
                final item = provider.categorySummary[i];
                return ListTile(
                  title: Text(item.category),
                  trailing: Text(CurrencyFormatter.format(item.totalAmount, widget.shop.currency ?? 'TZS'), style: const TextStyle(color: Colors.red)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesHistoryList(ExpenseReportProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Expenses History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            provider.expensesHistory.isEmpty && !provider.isLoadingHistory
                ? const Text('No expenses recorded')
                : ListView.builder(
                    controller: _historyController,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.expensesHistory.length + (provider.isLoadingHistory ? 1 : 0),
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
                        title: Text(description),
                        subtitle: Text('$category • ${DateFormat('dd MMM yyyy').format(date)}'),
                        trailing: Text(CurrencyFormatter.format(amount, widget.shop.currency ?? 'TZS'), style: const TextStyle(color: Colors.red)),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}