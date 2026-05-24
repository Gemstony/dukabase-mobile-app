import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/sales_report_provider.dart';
import '../../../core/models/shop_model.dart';

class SalesReportScreen extends StatefulWidget {
  final ShopModel shop;
  const SalesReportScreen({super.key, required this.shop});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
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
    final provider = Provider.of<SalesReportProvider>(context, listen: false);
    await provider.loadDailyReport(widget.shop.id, _startDate, _endDate);
    await provider.loadTopProducts(widget.shop.id, _startDate, _endDate);
    await provider.loadSalesHistory(widget.shop.id, refresh: true);
  }

  void _onHistoryScroll() {
    if (_historyController.position.pixels >=
        _historyController.position.maxScrollExtent - 200) {
      Provider.of<SalesReportProvider>(
        context,
        listen: false,
      ).loadSalesHistory(widget.shop.id);
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
    final provider = Provider.of<SalesReportProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales Report - ${widget.shop.name}'),
        actions: [
          IconButton(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.calendar_today),
          ),
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
              _buildDailySalesTable(provider),
              const SizedBox(height: 24),
              _buildTopProductsList(provider),
              const SizedBox(height: 24),
              _buildSalesHistoryList(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPISection(SalesReportProvider provider) {
    if (provider.isLoadingDaily && provider.dailyReport.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final totalSales = provider.dailyReport.fold(
      0.0,
      (sum, item) => sum + item.totalSales,
    );
    final totalTransactions = provider.dailyReport.fold(
      0,
      (sum, item) => sum + item.transactionCount,
    );
    final avgTransaction = totalTransactions > 0
        ? totalSales / totalTransactions
        : 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _kpiTile('Total Sales', totalSales),
            _kpiTile('Transactions', totalTransactions.toDouble()),
            _kpiTile('Average', avgTransaction.toDouble()),
          ],
        ),
      ),
    );
  }

  Widget _kpiTile(String title, double value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(2),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDailySalesTable(SalesReportProvider provider) {
    if (provider.isLoadingDaily)
      return const Center(child: CircularProgressIndicator());
    if (provider.dailyReport.isEmpty)
      return const Text('No sales data for this period');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Sales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: DataTable(
                columnSpacing: 12,
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Sales'), numeric: true),
                  DataColumn(label: Text('Orders'), numeric: true),
                ],
                rows: provider.dailyReport.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(DateFormat('dd MMM yyyy').format(item.date)),
                      ),
                      DataCell(Text(item.totalSales.toStringAsFixed(2))),
                      DataCell(Text(item.transactionCount.toString())),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsList(SalesReportProvider provider) {
    if (provider.isLoadingTop)
      return const Center(child: CircularProgressIndicator());
    if (provider.topProducts.isEmpty)
      return const Text('No product sales data');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Selling Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.topProducts.length,
              itemBuilder: (_, i) {
                final item = provider.topProducts[i];
                return ListTile(
                  title: Text(item.productName),
                  subtitle: Text(
                    'Quantity sold: ${item.quantitySold.toStringAsFixed(2)}',
                  ),
                  trailing: Text(item.revenue.toStringAsFixed(2)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesHistoryList(SalesReportProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            provider.salesHistory.isEmpty && !provider.isLoadingHistory
                ? const Text('No sales found')
                : ListView.builder(
                    controller: _historyController,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                        provider.salesHistory.length +
                        (provider.isLoadingHistory ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == provider.salesHistory.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final doc = provider.salesHistory[i];
                      final data = doc.data();
                      final date = (data['createdAt'] as Timestamp).toDate();
                      return ListTile(
                        title: Text('Sale #${doc.id.substring(0, 6)}'),
                        subtitle: Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(date),
                        ),
                        trailing: Text(
                          (data['totalAmount'] as num)
                              .toDouble()
                              .toStringAsFixed(2),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
