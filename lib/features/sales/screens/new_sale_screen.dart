import 'package:dukabase/features/payment_methods/providers/payment_method_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String? _selectedPaymentMethodId;
  final List<CartItem> _cart = [];
  String? _selectedCustomerId;
  final TextEditingController _paidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Provider.of<CustomerProvider>(
      context,
      listen: false,
    ).loadCustomers(widget.shop.id);
    Provider.of<ProductProvider>(
      context,
      listen: false,
    ).loadProducts(widget.shop.id);

    Provider.of<PaymentMethodProvider>(
      context,
      listen: false,
    ).loadPaymentMethods(widget.shop.id);
  }

  double get _totalAmount => _cart.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> _addProduct() async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    if (productProvider.products.isEmpty) {
      _showSnackBar('No products available. Create a product first.');
      return;
    }

    // Step 1: pick product
    final product = await _showProductPicker(productProvider.products);
    if (product == null) {
      print('Product selection cancelled');
      return;
    }
    print('Selected product: ${product.name} (${product.id})');

    // Step 2: get available batches for this product
    final batches = await _getBatchesForProduct(product.id);
    if (batches.isEmpty) {
      _showSnackBar(
        'No batches available for ${product.name}. Purchase stock first.',
      );
      return;
    }
    print('Found ${batches.length} batches');

    // Step 3: select batch (or auto-select if only one)
    BatchModel? batch;
    if (batches.length == 1) {
      batch = batches.first;
      print('Only one batch, auto-selected: ${batch.batchCode}');
    } else {
      batch = await _showBatchPicker(batches);
      if (batch == null) {
        print('Batch selection cancelled');
        return;
      }
      print('Selected batch: ${batch.batchCode}');
    }

    // Step 4: enter quantity
    final quantity = await _showQuantityDialog(batch.quantity);
    if (quantity == null || quantity <= 0) {
      print('Invalid quantity or cancelled');
      return;
    }
    print('Quantity: $quantity');

    // Step 5: add to cart
    setState(() {
      _cart.add(
        CartItem(
          productId: product.id,
          productName: product.name,
          batchId: batch!.id,
          batchCode: batch.batchCode,
          quantity: quantity,
          sellingPrice: batch.sellingPrice,
        ),
      );
    });
    _showSnackBar('${product.name} added to cart', isError: false);
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
              subtitle: Text(
                'Stock: ${products[i].currentStock} ${products[i].unit}',
              ),
              onTap: () => Navigator.pop(ctx, products[i]),
            ),
          ),
        ),
      ),
    );
  }

  Future<List<BatchModel>> _getBatchesForProduct(String productId) async {
    try {
      print('🔍 Fetching batches for productId: $productId');
      final batchRef = FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shop.id)
          .collection('products')
          .doc(productId)
          .collection('batches');

      print('📁 Batch reference path: ${batchRef.path}');

      final snapshot = await batchRef.get();
      print('📦 Total batches found (no filter): ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        print('Batch doc: ${doc.id} -> data: ${doc.data()}');
      }

      // Now filter with quantity > 0 manually (to avoid Firestore type issues)
      final batches = snapshot.docs
          .map((doc) => BatchModel.fromMap(doc.id, doc.data()))
          .where((batch) => batch.quantity > 0)
          .toList();
      print('✅ Batches with quantity > 0: ${batches.length}');
      return batches;
    } catch (e) {
      print('❌ Error fetching batches: $e');
      return [];
    }
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
                  'Qty: ${b.quantity} | Sell: ${b.sellingPrice}${b.expiryDate != null ? ' | Expiry: ${b.expiryDate!.toLocal().toString().split(' ')[0]}' : ''}',
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
          decoration: InputDecoration(
            labelText: 'Max: $maxQty',
            hintText: 'Enter quantity',
          ),
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
                _showSnackBar(
                  'Invalid quantity. Must be between 1 and $maxQty',
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _saveSale() async {
    if (_cart.isEmpty) {
      _showSnackBar('Add at least one item');
      return;
    }
    final paid = double.tryParse(_paidController.text);
    if (paid == null || paid < 0) {
      _showSnackBar('Enter valid paid amount');
      return;
    }

    final saleProvider = Provider.of<SaleProvider>(context, listen: false);
    final success = await saleProvider.recordSale(
      shopId: widget.shop.id,
      customerId: _selectedCustomerId,
      paymentMethodId: _selectedPaymentMethodId!,
      paidAmount: paid,
      items: _cart
          .map(
            (item) => (
              batchId: item.batchId,
              productId: item.productId,
              productName: item.productName,
              quantity: item.quantity,
              sellingPrice: item.sellingPrice,
            ),
          )
          .toList(),
    );

    if (success) {
      _showSnackBar('Sale recorded successfully', isError: false);
      Navigator.pop(context);
    } else {
      _showSnackBar(saleProvider.error ?? 'Failed to record sale');
      saleProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final paymentProvider = Provider.of<PaymentMethodProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('New Sale')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Customer'),
                  value: _selectedCustomerId,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Walk‑in Customer'),
                    ),
                    ...customerProvider.customers.map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.name} (${c.phone})'),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedCustomerId = val),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cart',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
                if (_cart.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No items. Tap + to add product.'),
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Payment Method *',
                  ),
                  value: _selectedPaymentMethodId,
                  items: paymentProvider.methods.map((method) {
                    return DropdownMenuItem(
                      value: method.id,
                      child: Text(
                        '${method.name} (Balance: ${method.currentBalance.toStringAsFixed(2)})',
                      ),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setState(() => _selectedPaymentMethodId = val),
                  validator: (v) => v == null ? 'Select payment method' : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'Total: ${_totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _paidController,
                  decoration: const InputDecoration(labelText: 'Amount Paid'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Text(
                  'Change: ${(double.tryParse(_paidController.text) ?? 0) - _totalAmount >= 0 ? ((double.tryParse(_paidController.text) ?? 0) - _totalAmount).toStringAsFixed(2) : '0.00'}',
                ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
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
