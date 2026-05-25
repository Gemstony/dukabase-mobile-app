import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/models/dashboard_data.dart';

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
      childAspectRatio: 1.5,
      children: [
        _kpiCard('Today Sales', data.todaySales, Icons.today, Colors.green),
        _kpiCard(
          'Today Expenses',
          data.todayExpenses,
          Icons.receipt,
          Colors.red,
        ),
        _kpiCard(
          'Today Profit',
          data.todayProfit,
          Icons.trending_up,
          Colors.blue,
        ),
        _kpiCard(
          'Total Products',
          data.totalProducts.toDouble(),
          Icons.inventory,
          Colors.purple,
        ),
        _kpiCard(
          'Low Stock Alerts',
          data.lowStockProducts.toDouble(),
          Icons.warning,
          Colors.orange,
        ),
        _kpiCard(
          'Active Suppliers',
          data.activeSuppliers.toDouble(),
          Icons.business,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _kpiCard(String title, double value, IconData icon, Color color) {
    return Card(
      elevation: 2,

      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(icon, size: 28, color: color),

            const SizedBox(height: 8),

            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,

                child: Text(
                  value.toStringAsFixed(2),

                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),

                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
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
