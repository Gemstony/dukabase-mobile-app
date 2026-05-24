import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_report_provider.dart';
import '../../../core/models/shop_model.dart';

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
      appBar: AppBar(title: Text('Product Report - ${widget.shop.name}')),
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
      (sum, p) => sum + (p.currentStock * (p.defaultSellingPrice)),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _kpiTile('Total Products', totalProducts.toDouble()),
            _kpiTile('Low Stock', lowStockCount.toDouble()),
            _kpiTile('Stock Value', totalStockValue),
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

  Widget _buildLowStockList(ProductReportProvider provider) {
    if (provider.lowStockProducts.isEmpty) return const SizedBox();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Low Stock Alerts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.lowStockProducts.length,
              itemBuilder: (_, i) {
                final p = provider.lowStockProducts[i];
                return ListTile(
                  leading: const Icon(Icons.warning, color: Colors.orange),
                  title: Text(p.name),
                  subtitle: Text(
                    'Stock: ${p.currentStock} ${p.unit} (Alert at ${p.lowStockAlert})',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(ProductReportProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            provider.isLoadingProducts && provider.products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.products.isEmpty
                ? const Text('No products found')
                : ListView.builder(
                    controller: _productController,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                        provider.products.length +
                        (provider.hasMoreProducts && provider.isLoadingProducts
                            ? 1
                            : 0),
                    itemBuilder: (_, i) {
                      if (i == provider.products.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final p = provider.products[i];
                      return ListTile(
                        title: Text(p.name),
                        subtitle: Text(
                          'SKU: ${p.sku} | Stock: ${p.currentStock} ${p.unit}',
                        ),
                        trailing: Text(
                          p.defaultSellingPrice.toStringAsFixed(2),
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
