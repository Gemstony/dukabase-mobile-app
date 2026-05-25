import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/models/dashboard_data.dart';
import '../../sales/screens/new_sale_screen.dart';
import '../../sales/screens/sales_list_screen.dart';
import '../../purchases/screens/purchases_list_screen.dart';
import '../../expenses/screens/expense_list_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  final ShopModel shop;
  const OwnerDashboardScreen({super.key, required this.shop});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<DashboardProvider>(
        context,
        listen: false,
      ).loadDashboard(widget.shop.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard - ${widget.shop.name}')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
          ? Center(child: Text('Error: ${provider.error}'))
          : RefreshIndicator(
              onRefresh: () async {
                provider.loadDashboard(widget.shop.id);
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKpiCards(provider.data!),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildLowStockSection(provider.data!.lowStockItems),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKpiCards(DashboardData data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _kpiCard('Today Sales', data.todaySales, Icons.trending_up, const [Color(0xFF38ef7d), Color(0xFF11998e)]),
        _kpiCard('Today Expenses', data.todayExpenses, Icons.receipt_long, const [Color(0xFFff9966), Color(0xFFff5e62)]),
        _kpiCard('Today Profit', data.todayProfit, Icons.account_balance_wallet, const [Color(0xFF56CCF2), Color(0xFF2F80ED)]),
        _kpiCard('Total Products', data.totalProducts.toDouble(), Icons.inventory_2, const [Color(0xFFa8c0ff), Color(0xFF3f2b96)]),
        _kpiCard('Low Stock Alerts', data.lowStockProducts.toDouble(), Icons.warning_amber_rounded, const [Color(0xFFF2C94C), Color(0xFFF2994A)]),
        _kpiCard('Active Suppliers', data.activeSuppliers.toDouble(), Icons.local_shipping, const [Color(0xFF1D976C), Color(0xFF93F9B9)]),
      ],
    );
  }

  Widget _kpiCard(String title, double value, IconData icon, List<Color> gradientColors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value.toStringAsFixed(value == value.truncateToDouble() ? 0 : 2),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _actionButton('New Sale', Icons.sell, Colors.blue.shade600, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => NewSaleScreen(shop: widget.shop)));
            }),
            _actionButton('Sales List', Icons.list_alt, Colors.teal.shade600, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => SalesListScreen(shop: widget.shop)));
            }),
            _actionButton('Purchases', Icons.inventory_2, Colors.purple.shade600, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PurchasesListScreen(shop: widget.shop)));
            }),
            _actionButton('Expenses', Icons.receipt_long, Colors.orange.shade600, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ExpenseListScreen(shop: widget.shop)));
            }),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockSection(List<LowStockProduct> lowStockItems) {
    if (lowStockItems.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('No low stock items'),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Low Stock Alerts',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lowStockItems.length,
          itemBuilder: (_, i) {
            final item = lowStockItems[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.warning, color: Colors.orange),
                title: Text(item.name),
                subtitle: Text(
                  'Stock: ${item.currentStock} ${item.unit} | Alert at: ${item.threshold}',
                ),
                trailing: TextButton(
                  onPressed: () {
                    // Navigate to product detail or purchase screen
                  },
                  child: const Text('Restock'),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
