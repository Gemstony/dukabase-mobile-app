import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_adjustment_provider.dart';
import '../../../core/models/shop_model.dart';
import 'create_stock_adjustment_screen.dart';

class StockAdjustmentListScreen extends StatefulWidget {
  final ShopModel shop;
  const StockAdjustmentListScreen({super.key, required this.shop});

  @override
  State<StockAdjustmentListScreen> createState() => _StockAdjustmentListScreenState();
}

class _StockAdjustmentListScreenState extends State<StockAdjustmentListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<StockAdjustmentProvider>(context, listen: false)
          .loadAdjustments(widget.shop.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StockAdjustmentProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Stock Adjustments - ${widget.shop.name}')),
      body: provider.isLoading && provider.adjustments.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.adjustments.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: provider.adjustments.length,
                  itemBuilder: (_, i) {
                    final adj = provider.adjustments[i];
                    final isPositive = adj.quantityChange > 0;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                        title: Text('Reason: ${adj.reason.toUpperCase()}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Product ID: ${adj.productId.substring(0, 6)}...'),
                            Text('Batch ID: ${adj.batchId.substring(0, 6)}...'),
                            if (adj.note != null) Text('Note: ${adj.note}'),
                            Text('Date: ${adj.createdAt.toLocal().toString().split(' ')[0]}'),
                          ],
                        ),
                        trailing: Text(
                          '${isPositive ? '+' : ''}${adj.quantityChange.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _openCreateAdjustment,
      ),
    );
  }

  Future<void> _openCreateAdjustment() async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateStockAdjustmentScreen(shop: widget.shop),
      ),
    );
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No stock adjustments yet'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _openCreateAdjustment,
            child: const Text('Create Adjustment'),
          ),
        ],
      ),
    );
  }
}