import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_adjustment_provider.dart';
import '../../../core/models/shop_model.dart';
import 'create_stock_adjustment_screen.dart';

class StockAdjustmentListScreen extends StatefulWidget {
  final ShopModel shop;
  const StockAdjustmentListScreen({super.key, required this.shop});

  @override
  State<StockAdjustmentListScreen> createState() =>
      _StockAdjustmentListScreenState();
}

class _StockAdjustmentListScreenState extends State<StockAdjustmentListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<StockAdjustmentProvider>(
        context,
        listen: false,
      ).loadAdjustments(widget.shop.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StockAdjustmentProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Stock Adjustments',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: provider.isLoading && provider.adjustments.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.adjustments.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.adjustments.length,
              itemBuilder: (context, index) {
                final adj = provider.adjustments[index];
                final isPositive = adj.quantityChange > 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isPositive
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isPositive
                                    ? Icons.add_circle_outline
                                    : Icons.remove_circle_outline,
                                size: 32,
                                color: isPositive ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reason: ${adj.reason.toUpperCase()}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Product ID: ${adj.batchId.substring(0, 6)}...',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (adj.note != null)
                                    Text(
                                      'Note: ${adj.note}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isPositive
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${isPositive ? '+' : ''}${adj.quantityChange.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: isPositive
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        adj.createdAt
                                            .toLocal()
                                            .toString()
                                            .split(' ')[0],
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Adjustment'),
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
