import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sale_provider.dart';
import '../../customers/providers/customer_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/batch_model.dart';

class NewSaleScreen extends StatefulWidget {
  final ShopModel shop;
  const NewSaleScreen({super.key, required this.shop});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final List<CartItem> _cart = [];
  String? _selectedCustomerId; // null = walk‑in
  String? _selectedPaymentMethodId; // placeholder
  final TextEditingController _paidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load customers and products
    Provider.of<CustomerProvider>(context, listen: false)
        .loadCustomers(widget.shop.id);
    Provider.of<ProductProvider>(context, listen: false)
        .loadProducts(widget.shop.id);
  }

  double get _totalAmount => _cart.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> _addProduct() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (productProvider.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products available. Create a product first.')),
      );
      return;
    }

    // Show product selection, then batch selection for that product
    final product = await _showProductPicker(productProvider.products);
    if (product == null) return;

    // Load batches for this product
    final batches = await _getBatchesForProduct(product.id);
    if (batches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No batches available for this product. Purchase stock first.')),
      );
      return;
    }

    final batch = await _showBatchPicker(batches);
    if (batch == null) return;

    final quantity = await _showQuantityDialog(batch.quantity);
    if (quantity == null || quantity <= 0) return;

    final sellingPrice = batch.sellingPrice; // can allow override
    setState(() {
      _cart.add(CartItem(
        productId: product.id,
        productName: product.name,
        batchId: batch.id,
        batchCode: batch.batchCode,
        quantity: quantity,
        sellingPrice: sellingPrice,
      ));
    });
  }

  Future<ProductModel?> _showProductPicker(List<ProductModel> products) async {
    return showDialog<ProductModel>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Product'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: products.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(products[i].name),
              subtitle: Text('Stock: ${products[i].currentStock} ${products[i].unit}'),
              onTap: () => Navigator.pop(ctx, products[i]),
            ),
          ),
        ),
      ),
    );
  }

  Future<List<BatchModel>> _getBatchesForProduct(String productId) async {
    // Since we don't have a service for batches yet, we'll query directly
    final snapshot = await FirebaseFirestore.instance
        .collection('shops')
        .doc(widget.shop.id)
        .collection('products')
        .doc(productId)
        .collection('batches')
        .where('quantity', isGreaterThan: 0)
        .orderBy('createdAt')
        .get();
    return snapshot.docs.map((doc) => BatchModel.fromMap(doc.id, doc.data())).toList();
  }

  Future<BatchModel?> _showBatchPicker(List<BatchModel> batches) async {
    return showDialog<BatchModel>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Batch'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: batches.length,
            itemBuilder: (_, i) {
              final b = batches[i];
              return ListTile(
                title: Text('Batch: ${b.batchCode}'),
                subtitle: Text(
                  'Qty: ${b.quantity} | Cost: ${b.costPrice} | Sell: ${b.sellingPrice}${b.expiryDate != null ? ' | Expiry: ${b.expiryDate!.toLocal().toString().split(' ')[0]}' : ''}',
                ),
                onTap: () => Navigator.pop(ctx, b),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<double?> _showQuantityDialog(double maxQty) async {
    final controller = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Quantity'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Max: $maxQty'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final qty = double.tryParse(controller.text);
              if (qty != null && qty > 0 && qty <= maxQty) {
                Navigator.pop(ctx, qty);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Invalid quantity')),
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item')),
      );
      return;
    }
    final paid = double.tryParse(_paidController.text);
    if (paid == null || paid < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid paid amount')),
      );
      return;
    }

    final saleProvider = Provider.of<SaleProvider>(context, listen: false);
    final success = await saleProvider.recordSale(
      shopId: widget.shop.id,
      customerId: _selectedCustomerId,
      paymentMethodId: _selectedPaymentMethodId ?? 'cash', // fallback
      paidAmount: paid,
      items: _cart.map((item) => (
        batchId: item.batchId,
        productId: item.productId,
        quantity: item.quantity,
        sellingPrice: item.sellingPrice,
      )).toList(),
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale recorded'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saleProvider.error ?? 'Failed'), backgroundColor: Colors.red),
      );
      saleProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('New Sale')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Customer selection
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Customer'),
                  value: _selectedCustomerId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Walk‑in Customer')),
                    ...customerProvider.customers.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.name} (${c.phone})'),
                    )),
                  ],
                  onChanged: (val) => setState(() => _selectedCustomerId = val),
                ),
                const SizedBox(height: 16),
                // Cart
                const Text('Cart', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._cart.asMap().entries.map((entry) {
                  int idx = entry.key;
                  CartItem item = entry.value;
                  return Card(
                    child: ListTile(
                      title: Text(item.productName),
                      subtitle: Text(
                        'Batch: ${item.batchCode} | Qty: ${item.quantity} | Price: ${item.sellingPrice}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() => _cart.removeAt(idx)),
                      ),
                    ),
                  );
                }),
                if (_cart.isEmpty) const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No items. Tap + to add product.'),
                ),
                const SizedBox(height: 16),
                // Total
                Text('Total: ${_totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                // Paid amount
                TextField(
                  controller: _paidController,
                  decoration: const InputDecoration(labelText: 'Amount Paid'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Text('Change: ${(double.tryParse(_paidController.text) ?? 0) - _totalAmount >= 0 ? ((double.tryParse(_paidController.text) ?? 0) - _totalAmount).toStringAsFixed(2) : '0.00'}'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addProduct,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveSale,
                    child: const Text('Complete Sale'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CartItem {
  final String productId;
  final String productName;
  final String batchId;
  final String batchCode;
  final double quantity;
  final double sellingPrice;
  double get subtotal => quantity * sellingPrice;
  CartItem({
    required this.productId,
    required this.productName,
    required this.batchId,
    required this.batchCode,
    required this.quantity,
    required this.sellingPrice,
  });
}