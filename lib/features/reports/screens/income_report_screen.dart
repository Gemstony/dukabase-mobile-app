import 'package:dukabase/core/models/report_models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/income_report_provider.dart';
import '../../../core/models/shop_model.dart';

class IncomeReportScreen extends StatefulWidget {
  final ShopModel shop;
  const IncomeReportScreen({super.key, required this.shop});

  @override
  State<IncomeReportScreen> createState() => _IncomeReportScreenState();
}

class _IncomeReportScreenState extends State<IncomeReportScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    Provider.of<IncomeReportProvider>(context, listen: false)
        .loadIncomeSummary(widget.shop.id, _startDate, _endDate);
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
    final provider = Provider.of<IncomeReportProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Income Report - ${widget.shop.name}'),
        actions: [
          IconButton(onPressed: _pickDateRange, icon: const Icon(Icons.calendar_today)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.error != null
                ? Center(child: Text('Error: ${provider.error}'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDateRangeCard(),
                        const SizedBox(height: 16),
                        _buildKPICards(provider.summary),
                        const SizedBox(height: 24),
                        _buildProfitabilityCard(provider.summary),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildDateRangeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Period', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}'),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.edit_calendar),
              label: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICards(IncomeSummary? summary) {
    if (summary == null) return const SizedBox();
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _incomeRow('Total Revenue', summary.totalRevenue, Colors.green),
            const Divider(),
            _incomeRow('Cost of Goods Sold (COGS)', summary.totalCogs, Colors.orange),
            const Divider(),
            _incomeRow('Gross Profit', summary.grossProfit, Colors.blue, isBold: true),
            const Divider(),
            _incomeRow('Total Expenses', summary.totalExpenses, Colors.red),
            const Divider(),
            _incomeRow('Net Profit', summary.netProfit, Colors.purple, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _incomeRow(String label, double value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 18,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitabilityCard(IncomeSummary? summary) {
    if (summary == null) return const SizedBox();
    final profitMargin = summary.totalRevenue > 0 ? (summary.netProfit / summary.totalRevenue) * 100 : 0;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profitability', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: profitMargin / 100,
              backgroundColor: Colors.grey[300],
              color: profitMargin >= 20 ? Colors.green : (profitMargin >= 10 ? Colors.orange : Colors.red),
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Net Profit Margin', style: TextStyle(color: Colors.grey[600])),
                Text('${profitMargin.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}