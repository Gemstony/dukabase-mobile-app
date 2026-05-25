import 'package:dukabase/features/payment_methods/providers/payment_method_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/purchase_provider.dart';
import '../../suppliers/providers/supplier_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/models/supplier_model.dart';
import '../../../core/models/product_model.dart';

class PurchaseScreen extends StatefulWidget {
  final ShopModel shop;
  const PurchaseScreen({super.key, required this.shop});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPaymentMethodId;
  SupplierModel? _selectedSupplier;
  double _paidAmount = 0;

  final List<PurchaseItem> _items = [];
  final TextEditingController _paidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load suppliers and products
    Provider.of<SupplierProvider>(
      context,
      listen: false,
    ).loadSuppliers(widget.shop.id);
    Provider.of<ProductProvider>(
      context,
      listen: false,
    ).loadProducts(widget.shop.id);

    Provider.of<PaymentMethodProvider>(
      context,
      listen: false,
    ).loadPaymentMethods(widget.shop.id);
  }

  double get _totalAmount => _items.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> _addItem() async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    if (productProvider.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No products available. Create a product first.'),
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddPurchaseItemScreen(products: productProvider.products),
      ),
    );
    if (result != null && result is PurchaseItem) {
      setState(() {
        _items.add(result);
      });
    }
  }

  Future<void> _savePurchase() async {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a supplier')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one item')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final purchaseProvider = Provider.of<PurchaseProvider>(
      context,
      listen: false,
    );
    final success = await purchaseProvider.recordPurchase(
      shopId: widget.shop.id,
      supplierId: _selectedSupplier!.id,
      supplierName: _selectedSupplier!.name,
      totalAmount: _totalAmount,
      paidAmount: _paidAmount,
      paymentMethodId: _selectedPaymentMethodId!,
      items: _items
          .map(
            (item) => (
              productId: item.productId,
              productName: item.productName,
              batchCode: item.batchCode,
              quantity: item.quantity,
              costPrice: item.costPrice,
              sellingPrice: item.sellingPrice,
              expiryDate: item.expiryDate,
            ),
          )
          .toList(),
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase recorded'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(purchaseProvider.error ?? 'Failed'),
          backgroundColor: Colors.red,
        ),
      );
      purchaseProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final supplierProvider = Provider.of<SupplierProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final paymentProvider = Provider.of<PaymentMethodProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('New Purchase')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Supplier dropdown
                  DropdownButtonFormField<SupplierModel>(
                    decoration: const InputDecoration(labelText: 'Supplier *'),
                    items: supplierProvider.suppliers.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s.name));
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedSupplier = value),
                    validator: (v) => v == null ? 'Select supplier' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Payment Method *',
                    ),
                    initialValue: _selectedPaymentMethodId,
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
                    validator: (v) =>
                        v == null ? 'Select payment method' : null,
                  ),
                  const SizedBox(height: 16),
                  // Items list
                  const Text(
                    'Items',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._items.asMap().entries.map((entry) {
                    int idx = entry.key;
                    PurchaseItem item = entry.value;
                    return Card(
                      child: ListTile(
                        title: Text(item.productName),
                        subtitle: Text(
                          'Batch: ${item.batchCode} | Qty: ${item.quantity} | Cost: ${item.costPrice} | Sell: ${item.sellingPrice}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _items.removeAt(idx)),
                        ),
                      ),
                    );
                  }),
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No items added. Tap + to add.'),
                    ),
                  const SizedBox(height: 16),
                  // Total amount
                  Text(
                    'Total Amount: ${_totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Paid amount
                  TextFormField(
                    controller: _paidController,
                    decoration: const InputDecoration(
                      labelText: 'Amount Paid *',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _paidAmount = double.tryParse(value) ?? 0;
                    },
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Balance: ${(_totalAmount - _paidAmount).toStringAsFixed(2)}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
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
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _savePurchase,
                      child: const Text('Save Purchase'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class to hold temporary purchase item data
class PurchaseItem {
  final String productId;
  final String productName;
  final String batchCode;
  final double quantity;
  final double costPrice;
  final double sellingPrice;
  final DateTime? expiryDate;
  double get subtotal => quantity * costPrice;

  PurchaseItem({
    required this.productId,
    required this.productName,
    required this.batchCode,
    required this.quantity,
    required this.costPrice,
    required this.sellingPrice,
    this.expiryDate,
  });
}

// Screen to add a single purchase item (batch)
class AddPurchaseItemScreen extends StatefulWidget {
  final List<ProductModel> products;
  const AddPurchaseItemScreen({super.key, required this.products});

  @override
  State<AddPurchaseItemScreen> createState() => _AddPurchaseItemScreenState();
}

class _AddPurchaseItemScreenState extends State<AddPurchaseItemScreen> {
  ProductModel? _selectedProduct;
  final _batchCodeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  DateTime? _expiryDate;

  @override
  void dispose() {
    _batchCodeController.dispose();
    _quantityController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  void _save() {
    if (_selectedProduct == null) return;
    final quantity = double.tryParse(_quantityController.text);
    final costPrice = double.tryParse(_costPriceController.text);
    final sellingPrice = double.tryParse(_sellingPriceController.text);
    if (quantity == null || costPrice == null || sellingPrice == null) return;
    if (_batchCodeController.text.isEmpty) return;

    Navigator.pop(
      context,
      PurchaseItem(
        productId: _selectedProduct!.id,
        productName: _selectedProduct!.name,
        batchCode: _batchCodeController.text,
        quantity: quantity,
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        expiryDate: _expiryDate,
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Add Item to Purchase'),
    ),

    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            DropdownButtonFormField<ProductModel>(
              decoration: const InputDecoration(
                labelText: 'Product *',
              ),

              items: widget.products.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(
                    p.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),

              onChanged: (value) {
                setState(() => _selectedProduct = value);
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _batchCodeController,
              decoration: const InputDecoration(
                labelText: 'Batch Code *',
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity *',
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _costPriceController,
              decoration: const InputDecoration(
                labelText: 'Cost Price *',
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _sellingPriceController,
              decoration: const InputDecoration(
                labelText: 'Selling Price *',
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                title: const Text(
                  'Expiry Date (optional)',
                ),

                subtitle: _expiryDate == null
                    ? const Text('Not set')
                    : Text(
                        _expiryDate!
                            .toLocal()
                            .toString()
                            .split(' ')[0],
                      ),

                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),

                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 5),
                      ),
                    );

                    if (date != null) {
                      setState(() => _expiryDate = date);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: _save,

                child: const Text(
                  'Add to Purchase',
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}
}
