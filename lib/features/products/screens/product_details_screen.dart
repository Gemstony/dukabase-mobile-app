import 'package:dukabase/features/products/providers/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/shop_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/batch_model.dart';
import '../../../core/models/sale_model.dart';
import '../../../core/models/purchase_model.dart';
import '../../../core/services/product_service.dart';
import '../../../core/utils/currency_formatter.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ShopModel shop;
  final ProductModel product;

  const ProductDetailsScreen({
    super.key,
    required this.shop,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProductService _productService = ProductService();
  late ProductModel _currentProduct;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_currentProduct.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Product',
            onPressed: () => _showEditProductModal(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Color.fromARGB(255, 222, 226, 241),
          unselectedLabelColor: Color.fromARGB(255, 222, 226, 241),
          tabs: const [
            Tab(text: 'Overview & Batches'),
            Tab(text: 'Recent Activity'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildActivityTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 24),
          const Text('Inventory Batches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildBatchesList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final isLowStock = _currentProduct.currentStock <= _currentProduct.lowStockAlert;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SKU: ${_currentProduct.sku}',
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLowStock ? Colors.redAccent : Colors.greenAccent.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isLowStock ? 'LOW STOCK' : 'IN STOCK',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${_currentProduct.currentStock} ${_currentProduct.unit}',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Total Available Stock',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Alert At',
                  '${_currentProduct.lowStockAlert} ${_currentProduct.unit}',
                  Icons.warning_amber_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _buildMiniStat(
                  'Default Price',
                  CurrencyFormatter.format(_currentProduct.defaultSellingPrice, widget.shop.currency ?? "TZS"),
                  Icons.sell_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildBatchesList() {
    return StreamBuilder<List<BatchModel>>(
      stream: _productService.getBatches(widget.shop.id, _currentProduct.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyContainer('No batches available for this product.');
        }

        final batches = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: batches.length,
          itemBuilder: (context, index) {
            final batch = batches[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.inventory_2, color: Colors.deepPurple),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Batch: ${batch.batchCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('Qty: ${batch.quantity}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                            const SizedBox(width: 12),
                            Text(
                              'Expiry: ${batch.expiryDate != null ? DateFormat('MMM d, y').format(batch.expiryDate!) : 'N/A'}',
                              style: TextStyle(color: Colors.red[400], fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Cost: ${CurrencyFormatter.format(batch.costPrice, widget.shop.currency ?? "TZS")}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('Sell: ${CurrencyFormatter.format(batch.sellingPrice, widget.shop.currency ?? "TZS")}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActivityTab() {
    // For performance and pagination reasons, we fetch the most recent items
    // across the shop's sales that contain this specific product ID using an indexed limit.
    // NOTE: This uses collectionGroup for 'items' subcollections, querying up to 30 recent operations.
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('items')
          .where('productId', isEqualTo: _currentProduct.id)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // This will expose the missing index URL if Firestore requires one
          print("Firestore Activity Query Error: ${snapshot.error}");
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildEmptyContainer('Error: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildEmptyContainer('No recent sales or purchases recorded.'),
          );
        }

        final docs = snapshot.data!.docs;
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            // Differentiate between sale and purchase by checking fields
            final isSale = data.containsKey('sellingPrice');
            final price = isSale ? data['sellingPrice'] : data['costPrice'];
            final qty = data['quantity'];
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSale ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isSale ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    child: Icon(isSale ? Icons.arrow_upward : Icons.arrow_downward, color: isSale ? Colors.green : Colors.orange),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSale ? 'Item Sold' : 'Item Purchased',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Batch: ${data['batchId'] ?? 'Unknown'}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isSale ? '-' : '+'}$qty ${_currentProduct.unit}',
                        style: TextStyle(
                          color: isSale ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@ ${CurrencyFormatter.format((price as num).toDouble(), widget.shop.currency ?? "TZS")}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyContainer(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _showEditProductModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: _currentProduct.name);
    final unitController = TextEditingController(text: _currentProduct.unit);
    final priceController = TextEditingController(text: _currentProduct.defaultSellingPrice.toString());
    final alertController = TextEditingController(text: _currentProduct.lowStockAlert.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Edit Product', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Product Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: unitController,
                    decoration: const InputDecoration(labelText: 'Unit (e.g., pcs, kg)'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Default Selling Price'),
                    keyboardType: TextInputType.number,
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid price' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: alertController,
                    decoration: const InputDecoration(labelText: 'Low Stock Alert Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid quantity' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(ctx);
                        
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (c) => const Center(child: CircularProgressIndicator()),
                        );
                        
                        // Wait for provider to perform update
                        // ignore: use_build_context_synchronously
                        final productProvider = Provider.of<ProductProvider>(context, listen: false);
                        
                        final price = double.parse(priceController.text);
                        final alert = double.parse(alertController.text);
                        
                        final success = await productProvider.updateProduct(
                          shopId: widget.shop.id,
                          productId: _currentProduct.id,
                          name: nameController.text.trim(),
                          unit: unitController.text.trim(),
                          defaultSellingPrice: price,
                          lowStockAlert: alert,
                        );
                        
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context); // close loading
                        
                        if (success) {
                          setState(() {
                            // Rebuild UI with local modifications
                            _currentProduct = ProductModel(
                              id: _currentProduct.id,
                              shopId: _currentProduct.shopId,
                              name: nameController.text.trim(),
                              sku: _currentProduct.sku,
                              unit: unitController.text.trim(),
                              defaultSellingPrice: price,
                              currentStock: _currentProduct.currentStock,
                              lowStockAlert: alert,
                              createdAt: _currentProduct.createdAt,
                              updatedAt: DateTime.now(),
                            );
                          });
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Product updated successfully'), backgroundColor: Colors.green),
                          );
                        } else {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(productProvider.error ?? 'Update failed'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
