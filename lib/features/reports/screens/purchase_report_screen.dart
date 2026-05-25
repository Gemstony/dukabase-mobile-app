import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/purchase_report_provider.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/utils/currency_formatter.dart';

class PurchaseReportScreen extends StatefulWidget {
  final ShopModel shop;
  const PurchaseReportScreen({super.key, required this.shop});

  @override
  State<PurchaseReportScreen> createState() => _PurchaseReportScreenState();
}

class _PurchaseReportScreenState extends State<PurchaseReportScreen> {
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
    final provider = Provider.of<PurchaseReportProvider>(
      context,
      listen: false,
    );
    await provider.loadDailyReport(widget.shop.id, _startDate, _endDate);
    await provider.loadTopProducts(widget.shop.id, _startDate, _endDate);
    await provider.loadSupplierSummary(widget.shop.id, _startDate, _endDate);
    await provider.loadPurchaseHistory(widget.shop.id, refresh: true);
  }

  void _onHistoryScroll() {
    if (_historyController.position.pixels >=
        _historyController.position.maxScrollExtent - 200) {
      Provider.of<PurchaseReportProvider>(
        context,
        listen: false,
      ).loadPurchaseHistory(widget.shop.id);
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
    final provider = Provider.of<PurchaseReportProvider>(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Purchase Report - ${widget.shop.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.calendar_month_rounded, color: Colors.blue),
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
              _buildDailyPurchaseTable(provider),
              const SizedBox(height: 24),
              _buildTopPurchasedList(provider),
              const SizedBox(height: 24),
              _buildSupplierSummaryList(provider),
              const SizedBox(height: 24),
              _buildPurchaseHistoryList(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPISection(PurchaseReportProvider provider) {
    if (provider.isLoadingDaily && provider.dailyReport.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final totalPurchases = provider.dailyReport.fold(0.0, (sum, item) => sum + item.totalPurchases);
    final totalTransactions = provider.dailyReport.fold(0, (sum, item) => sum + item.purchaseCount);
    final avgPurchase = totalTransactions > 0 ? totalPurchases / totalTransactions : 0.0;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _kpiTile('Total Purchases', CurrencyFormatter.format(totalPurchases, widget.shop.currency ?? 'TZS')),
              ),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
              Expanded(
                child: _kpiTile('Orders', totalTransactions.toString()),
              ),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
              Expanded(
                child: _kpiTile('Avg Order', CurrencyFormatter.format(avgPurchase, widget.shop.currency ?? 'TZS')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiTile(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: Colors.white70)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ],
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

  Widget _buildDailyPurchaseTable(PurchaseReportProvider provider) {
    if (provider.isLoadingDaily) return const Center(child: CircularProgressIndicator());
    if (provider.dailyReport.isEmpty) return const Text('No purchase data for this period', style: TextStyle(color: Colors.grey));
    
    return _buildCard(
      title: 'Daily Purchases',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
          columnSpacing: 24,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 48,
          columns: const [
            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Purchases', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Orders', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
          ],
          rows: provider.dailyReport.map((item) {
            return DataRow(
              cells: [
                DataCell(Text(DateFormat('dd MMM yyyy').format(item.date), style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(Text(CurrencyFormatter.format(item.totalPurchases, widget.shop.currency ?? 'TZS'), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                DataCell(Text(item.purchaseCount.toString())),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopPurchasedList(PurchaseReportProvider provider) {
    if (provider.isLoadingTop) return const Center(child: CircularProgressIndicator());
    if (provider.topProducts.isEmpty) return const Text('No purchase data', style: TextStyle(color: Colors.grey));
    
    return _buildCard(
      title: 'Top Purchased Products',
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: provider.topProducts.length,
        separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100),
        itemBuilder: (_, i) {
          final item = provider.topProducts[i];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade50,
              child: Text('${i + 1}', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
            ),
            title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Qty: ${item.quantitySold.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey.shade600)),
            trailing: Text(
              CurrencyFormatter.format(item.revenue, widget.shop.currency ?? 'TZS'),
              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSupplierSummaryList(PurchaseReportProvider provider) {
    if (provider.isLoadingSuppliers) return const Center(child: CircularProgressIndicator());
    if (provider.supplierSummary.isEmpty) return const Text('No supplier data', style: TextStyle(color: Colors.grey));
    
    return _buildCard(
      title: 'Supplier Summary',
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: provider.supplierSummary.length,
        separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100),
        itemBuilder: (_, i) {
          final supp = provider.supplierSummary[i];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.shade50,
              child: Icon(Icons.local_shipping, color: Colors.indigo.shade400),
            ),
            title: Text(supp.supplierName, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Text(
              CurrencyFormatter.format(supp.totalAmount, widget.shop.currency ?? 'TZS'),
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPurchaseHistoryList(PurchaseReportProvider provider) {
    return _buildCard(
      title: 'Purchase History',
      child: provider.purchaseHistory.isEmpty && !provider.isLoadingHistory
          ? const Text('No purchases found', style: TextStyle(color: Colors.grey))
          : ListView.separated(
              controller: _historyController,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.purchaseHistory.length + (provider.isLoadingHistory ? 1 : 0),
              separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100),
              itemBuilder: (_, i) {
                if (i == provider.purchaseHistory.length) {
                  return const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()));
                }
                final doc = provider.purchaseHistory[i];
                final data = doc.data();
                final date = (data['createdAt'] as Timestamp).toDate();
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade50,
                    child: Icon(Icons.receipt, color: Colors.orange.shade500),
                  ),
                  title: Text('PO #${doc.id.substring(0, 6).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(date), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  trailing: Text(
                    CurrencyFormatter.format((data['totalAmount'] as num).toDouble(), widget.shop.currency ?? 'TZS'),
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                );
              },
            ),
    );
  }
}
