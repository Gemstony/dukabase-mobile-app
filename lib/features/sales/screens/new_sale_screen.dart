import 'package:dukabase/core/utils/currency_formatter.dart';
import 'package:dukabase/core/widgets/transaction_form_ui.dart';
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
import 'sales_list_screen.dart';

class NewSaleScreen extends StatefulWidget {
  final ShopModel shop;
  const NewSaleScreen({super.key, required this.shop});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _formKey = GlobalKey<FormState>();
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

  String _formatAmount(double amount) =>
      CurrencyFormatter.format(amount, widget.shop.currency);

  Future<ProductModel?> _showProductPicker(List<ProductModel> products) async {
    return showDialog<ProductModel>(
      context: context,
      builder: (ctx) => TransactionFormUi.styledDialog(
        title: 'Select Product',
        icon: Icons.inventory_2_outlined,
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: products.length,
            itemBuilder: (_, i) {
              final p = products[i];
              return TransactionFormUi.dialogListTile(
                title: p.name,
                subtitle: 'Stock: ${p.currentStock} ${p.unit}',
                icon: Icons.shopping_bag_outlined,
                onTap: () => Navigator.pop(ctx, p),
              );
            },
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
      builder: (ctx) => TransactionFormUi.styledDialog(
        title: 'Select Batch',
        icon: Icons.layers_outlined,
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: batches.length,
            itemBuilder: (_, i) {
              final b = batches[i];
              final expiry = b.expiryDate != null
                  ? ' · Exp ${b.expiryDate!.toLocal().toString().split(' ')[0]}'
                  : '';
              return TransactionFormUi.dialogListTile(
                title: 'Batch ${b.batchCode}',
                subtitle:
                    'Qty ${b.quantity} · ${_formatAmount(b.sellingPrice)}$expiry',
                icon: Icons.qr_code_2_outlined,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.numbers, color: Colors.deepPurple, size: 22),
            SizedBox(width: 10),
            Text('Enter Quantity'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: TransactionFormUi.fieldDecoration(
            ctx,
            label: 'Quantity',
            prefixIcon: Icons.shopping_cart_outlined,
            hint: 'Max available: $maxQty',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
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
            child: const Text('Add'),
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
    if (_selectedPaymentMethodId == null) {
      _showSnackBar('Please select a payment method');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SalesListScreen(shop: widget.shop)),
      );
    } else {
      _showSnackBar(saleProvider.error ?? 'Failed to record sale');
      saleProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final paymentProvider = Provider.of<PaymentMethodProvider>(context);
    final paid = double.tryParse(_paidController.text) ?? 0;
    final change = paid - _totalAmount;
    final changeDisplay = change >= 0 ? change : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        actions: [
          if (_cart.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_cart.length} item${_cart.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  TransactionFormUi.sectionHeader(
                    icon: Icons.person_outline,
                    title: 'Customer',
                    subtitle: 'Optional — defaults to walk-in',
                  ),
                  TransactionFormUi.formCard(
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: TransactionFormUi.fieldDecoration(
                          context,
                          label: 'Customer',
                          prefixIcon: Icons.people_outline,
                        ),
                        initialValue: _selectedCustomerId,
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
                        onChanged: (val) =>
                            setState(() => _selectedCustomerId = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TransactionFormUi.sectionHeader(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Cart',
                    subtitle: _cart.isEmpty
                        ? 'Add products to start the sale'
                        : '${_cart.length} product${_cart.length == 1 ? '' : 's'} in cart',
                  ),
                  if (_cart.isEmpty)
                    TransactionFormUi.emptyItemsState(
                      message:
                          'Your cart is empty.\nTap "Add Product" to add items.',
                      icon: Icons.shopping_cart_outlined,
                    )
                  else
                    ..._cart.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return TransactionFormUi.lineItemCard(
                        title: item.productName,
                        trailingAmount: _formatAmount(item.subtotal),
                        chips: [
                          'Batch ${item.batchCode}',
                          'Qty ${item.quantity}',
                          'Price ${_formatAmount(item.sellingPrice)}',
                        ],
                        onRemove: () => setState(() => _cart.removeAt(idx)),
                      );
                    }),
                  const SizedBox(height: 20),
                  TransactionFormUi.sectionHeader(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Payment',
                    subtitle: 'How the customer is paying',
                  ),
                  TransactionFormUi.formCard(
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: TransactionFormUi.fieldDecoration(
                          context,
                          label: 'Payment Method *',
                          prefixIcon: Icons.payment_outlined,
                        ),
                        initialValue: _selectedPaymentMethodId,
                        items: paymentProvider.methods.map((method) {
                          return DropdownMenuItem(
                            value: method.id,
                            child: Text(
                              '${method.name} · ${_formatAmount(method.currentBalance)}',
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedPaymentMethodId = val),
                        validator: (v) =>
                            v == null ? 'Select payment method' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TransactionFormUi.sectionHeader(
                    icon: Icons.receipt_long_outlined,
                    title: 'Checkout',
                  ),
                  TransactionFormUi.paymentSummaryCard(
                    totalLabel: 'Sale total',
                    totalValue: _formatAmount(_totalAmount),
                    secondaryLabel: 'Change due',
                    secondaryValue: _formatAmount(changeDisplay),
                    secondaryColor: changeDisplay > 0
                        ? Colors.greenAccent.shade100
                        : Colors.white,
                  ),
                  const SizedBox(height: 14),
                  TransactionFormUi.formCard(
                    children: [
                      TextFormField(
                        controller: _paidController,
                        decoration: TransactionFormUi.fieldDecoration(
                          context,
                          label: 'Amount Paid *',
                          prefixIcon: Icons.paid_outlined,
                          hint: 'Enter amount received',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TransactionFormUi.bottomActionBar(
              secondaryButton: TransactionFormUi.secondaryButton(
                onPressed: _addProduct,
                label: 'Add Product',
                icon: Icons.add,
              ),
              primaryButton: TransactionFormUi.primaryButton(
                onPressed: _saveSale,
                label: 'Complete Sale',
                icon: Icons.check_circle_outline,
              ),
            ),
          ],
        ),
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
