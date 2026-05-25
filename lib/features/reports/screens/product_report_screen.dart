import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_report_provider.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/utils/currency_formatter.dart';

class ProductReportScreen extends StatefulWidget {
  final ShopModel shop;
  const ProductReportScreen({super.key, required this.shop});

  @override
  State<ProductReportScreen> createState() => _ProductReportScreenState();
}

class _ProductReportScreenState extends State<ProductReportScreen> {
  final ScrollController _productController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProductReportProvider>(
        context,
        listen: false,
      );
      provider.loadProducts(widget.shop.id, refresh: true);
      provider.loadLowStockProducts(widget.shop.id);
    });
    _productController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_productController.position.pixels >=
        _productController.position.maxScrollExtent - 200) {
      Provider.of<ProductReportProvider>(
        context,
        listen: false,
      ).loadProducts(widget.shop.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductReportProvider>(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Product Report - ${widget.shop.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.loadProducts(widget.shop.id, refresh: true);
          await provider.loadLowStockProducts(widget.shop.id);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKPISection(provider),
              const SizedBox(height: 24),
              _buildLowStockList(provider),
              const SizedBox(height: 24),
              _buildProductList(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPISection(ProductReportProvider provider) {
    final totalProducts = provider.products.length;
    final lowStockCount = provider.lowStockProducts.length;
    final totalStockValue = provider.products.fold(
      0.0,
      (sum, p) => sum + (p.currentStock * p.defaultSellingPrice),
    );
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade500, Colors.indigo.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _kpiTile('Total Products', totalProducts.toString()),
              ),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
              Expanded(
                child: _kpiTile('Low Stock', lowStockCount.toString(), isAlert: lowStockCount > 0),
              ),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
              Expanded(
                child: _kpiTile('Stock Value', CurrencyFormatter.format(totalStockValue, widget.shop.currency ?? 'TZS')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiTile(String title, String value, {bool isAlert = false}) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: Colors.white70)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold, 
            color: isAlert ? Colors.orangeAccent : Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required Widget child, Color? titleColor}) {
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
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor ?? Colors.black87)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockList(ProductReportProvider provider) {
    if (provider.lowStockProducts.isEmpty) return const SizedBox();
    return _buildCard(
      title: 'Low Stock Alerts',
      titleColor: Colors.red.shade600,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: provider.lowStockProducts.length,
        separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100),
        itemBuilder: (_, i) {
          final p = provider.lowStockProducts[i];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade50,
              child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade500),
            ),
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Alert threshold: ${p.lowStockAlert}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${p.currentStock} ${p.unit}',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Text('Current Stock', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductList(ProductReportProvider provider) {
    return _buildCard(
      title: 'All Products',
      child: provider.isLoadingProducts && provider.products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.products.isEmpty
              ? const Text('No products found', style: TextStyle(color: Colors.grey))
              : ListView.separated(
                  controller: _productController,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.products.length + (provider.hasMoreProducts && provider.isLoadingProducts ? 1 : 0),
                  separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100),
                  itemBuilder: (_, i) {
                    if (i == provider.products.length) {
                      return const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()));
                    }
                    final p = provider.products[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: Icon(Icons.inventory_2_outlined, color: Colors.blue.shade500),
                      ),
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('SKU: ${p.sku} | Stock: ${p.currentStock} ${p.unit}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      trailing: Text(
                        CurrencyFormatter.format(p.defaultSellingPrice, widget.shop.currency ?? 'TZS'),
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    );
                  },
                ),
    );
  }
}
