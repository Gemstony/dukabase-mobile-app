import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/models/dashboard_data.dart';
import '../../sales/screens/new_sale_screen.dart';
import '../../sales/screens/sales_list_screen.dart';
import '../../purchases/screens/purchases_list_screen.dart';
import '../../expenses/screens/expense_list_screen.dart';
import '../../products/screens/product_list_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  final ShopModel shop;
  const StaffDashboardScreen({super.key, required this.shop});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<DashboardProvider>(context, listen: false)
          .loadDashboard(widget.shop.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Staff Dashboard - ${widget.shop.name}')),
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
                      children: [
                        _buildStaffStats(provider.data!),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStaffStats(DashboardData data) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Today\'s Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Sales', data.todaySales, Icons.shopping_cart, Colors.greenAccent),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
              _statItem('Expenses', data.todayExpenses, Icons.receipt, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, double value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white70),
        ),
        Text(
          value.toStringAsFixed(2),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
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
            _actionButton('Products', Icons.inventory, Colors.indigo.shade600, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProductListScreen(shop: widget.shop)));
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
}