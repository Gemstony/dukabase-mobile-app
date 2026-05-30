import 'package:dukabase/core/utils/connectivity_helper.dart';
import 'package:dukabase/core/utils/currency_formatter.dart';
import 'package:dukabase/core/utils/qr_code_helper.dart';
import 'package:dukabase/core/widgets/transaction_form_ui.dart';
import 'package:dukabase/features/payment_methods/providers/payment_method_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/product_service.dart';
import '../providers/sale_provider.dart';
import '../../customers/providers/customer_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/batch_model.dart';
import 'sales_list_screen.dart';
import 'barcode_scanner_screen.dart';

class NewSaleScreen extends StatefulWidget {
  final ShopModel shop;
  const NewSaleScreen({super.key, required this.shop});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  String? _selectedPaymentMethodId;
  final List<CartItem> _cart = [];
  String? _selectedCustomerId;
  final TextEditingController _paidController = TextEditingController();
  bool _isProcessingScan = false;
  bool _isSaving = false;

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

  // ─────────────────────────────────────────────────────────────
  // SCAN QR CODE → ADD TO CART
  // ─────────────────────────────────────────────────────────────

  /// Opens the barcode scanner, decodes the QR data, finds the matching
  /// product + batch, and adds it to the cart with quantity 1.
  Future<void> _addFromScan() async {
    if (_isProcessingScan) return;
    setState(() => _isProcessingScan = true);

    try {
      // 1. Open scanner
      final scannedValue = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
      );

      if (scannedValue == null || scannedValue.isEmpty) return;

      // 2. Decode QR data (format: "shopId|productId|batchCode")
      final decoded = QRCodeHelper.decodeBatchData(scannedValue);
      if (decoded == null) {
        _showSnackBar(
          'Invalid QR code format. Expected a valid batch QR code.',
        );
        return;
      }

      // 3. Validate shop matches
      if (decoded.shopId != widget.shop.id) {
        _showSnackBar('This QR code belongs to a different shop.');
        return;
      }

      // 4. Find the product
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      final product = productProvider.products
          .where((p) => p.id == decoded.productId)
          .firstOrNull;

      if (product == null) {
        _showSnackBar('Product not found. It may have been deleted.');
        return;
      }

      // 5. Find the batch with matching batchCode and available stock
      final batches = await _productService.getActiveBatches(
        widget.shop.id,
        product.id,
      );
      final batch = batches
          .where((b) => b.batchCode == decoded.batchCode && b.quantity > 0)
          .firstOrNull;

      if (batch == null) {
        _showSnackBar(
          'Batch "${decoded.batchCode}" for ${product.name} has no stock available.',
        );
        return;
      }

      // 6. Check if already in cart — if so increment quantity
      final existingIndex = _cart.indexWhere(
        (item) => item.batchId == batch.id,
      );

      if (existingIndex >= 0) {
        final existing = _cart[existingIndex];
        if (existing.quantity >= batch.quantity) {
          _showSnackBar(
            'Maximum stock (${batch.quantity}) reached for ${product.name} (${batch.batchCode}).',
          );
          return;
        }
        setState(() {
          _cart[existingIndex] = CartItem(
            productId: existing.productId,
            productName: existing.productName,
            batchId: existing.batchId,
            batchCode: existing.batchCode,
            quantity: existing.quantity + 1,
            sellingPrice: existing.sellingPrice,
            maxQuantity: batch.quantity,
          );
        });
        _showSnackBar(
          '${product.name} quantity increased to ${_cart[existingIndex].quantity}',
          isError: false,
        );
      } else {
        // 7. Add to cart with quantity 1
        setState(() {
          _cart.add(
            CartItem(
              productId: product.id,
              productName: product.name,
              batchId: batch.id,
              batchCode: batch.batchCode,
              quantity: 1,
              sellingPrice: batch.sellingPrice,
              maxQuantity: batch.quantity,
            ),
          );
        });
        _showSnackBar(
          '${product.name} (${batch.batchCode}) added to cart',
          isError: false,
        );
      }
    } catch (e) {
      _showSnackBar('Scan error: $e');
    } finally {
      if (mounted) setState(() => _isProcessingScan = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // MANUAL ADD PRODUCT
  // ─────────────────────────────────────────────────────────────

  Future<void> _addProductManually() async {
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
    if (product == null) return;

    // Step 2: get available batches for this product
    final batches = await _getBatchesForProduct(product.id);
    if (batches.isEmpty) {
      final offline = !await ConnectivityHelper.isOnline();
      _showSnackBar(
        offline
            ? 'No batch data for ${product.name} on this device. '
                  'Open the shop while online once, or add stock while connected.'
            : 'No batches available for ${product.name}. Purchase stock first.',
      );
      return;
    }

    // Step 3: select batch (or auto-select if only one)
    BatchModel? batch;
    if (batches.length == 1) {
      batch = batches.first;
    } else {
      batch = await _showBatchPicker(batches);
      if (batch == null) return;
    }

    // Step 4: enter quantity
    final quantity = await _showQuantityDialog(batch.quantity);
    if (quantity == null || quantity <= 0) return;

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
          maxQuantity: batch.quantity,
        ),
      );
    });
    _showSnackBar('${product.name} added to cart', isError: false);
  }

  // ─────────────────────────────────────────────────────────────
  // INCREMENT / DECREMENT QUANTITY
  // ─────────────────────────────────────────────────────────────

  void _incrementQuantity(int index) {
    if (index >= _cart.length) return;
    final item = _cart[index];
    // Check batch stock limit
    if (item.quantity >= item.maxQuantity) {
      _showSnackBar(
        'Maximum stock reached (${item.maxQuantity}) for ${item.productName} (${item.batchCode}).',
      );
      return;
    }
    setState(() {
      _cart[index] = CartItem(
        productId: item.productId,
        productName: item.productName,
        batchId: item.batchId,
        batchCode: item.batchCode,
        quantity: item.quantity + 1,
        sellingPrice: item.sellingPrice,
        maxQuantity: item.maxQuantity,
      );
    });
  }

  void _decrementQuantity(int index) {
    if (index >= _cart.length) return;
    final item = _cart[index];
    if (item.quantity <= 1) {
      // Remove item when quantity reaches 0
      setState(() => _cart.removeAt(index));
      return;
    }
    setState(() {
      _cart[index] = CartItem(
        productId: item.productId,
        productName: item.productName,
        batchId: item.batchId,
        batchCode: item.batchCode,
        quantity: item.quantity - 1,
        sellingPrice: item.sellingPrice,
        maxQuantity: item.maxQuantity,
      );
    });
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

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

  Future<List<BatchModel>> _getBatchesForProduct(String productId) {
    return _productService.getActiveBatches(widget.shop.id, productId);
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

  // ─────────────────────────────────────────────────────────────
  // SAVE SALE
  // ─────────────────────────────────────────────────────────────

  Future<void> _saveSale() async {
    if (_isSaving) return; // Prevent double clicks

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

    // If paid amount is less than total, ask for confirmation
    if (paid < _totalAmount) {
      final confirmed = await _showShortPaymentConfirmation(paid);
      if (confirmed != true) return;
    }

    setState(() => _isSaving = true);

    try {
      final saleProvider = Provider.of<SaleProvider>(context, listen: false);
      final result = await saleProvider.recordSale(
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

      if (!mounted) return;

      if (result.success) {
        final message = result.pendingSync
            ? 'Sale saved offline — will sync when you\'re back online'
            : 'Sale recorded successfully';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SalesListScreen(shop: widget.shop, successMessage: message),
          ),
        );
      } else {
        _showSnackBar(saleProvider.error ?? 'Failed to record sale');
        saleProvider.clearError();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Sale error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Shows a confirmation dialog when the customer pays less than the total.
  /// Returns `true` if the user confirms they want to proceed with the short payment.
  Future<bool?> _showShortPaymentConfirmation(double paid) async {
    final unpaid = _totalAmount - paid;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
            SizedBox(width: 10),
            Expanded(child: Text('Incomplete Payment')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The amount paid is less than the total sale amount.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _confirmationRow('Sale Total', _formatAmount(_totalAmount)),
            const SizedBox(height: 6),
            _confirmationRow('Amount Paid', _formatAmount(paid)),
            const SizedBox(height: 6),
            _confirmationRow(
              'Remaining Balance',
              _formatAmount(unpaid),
              valueColor: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedCustomerId != null
                  ? 'The remaining balance will be added to the customer\'s account.'
                  : 'Select a customer to track the remaining balance as credit.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Sale'),
          ),
        ],
      ),
    );
  }

  Widget _confirmationRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
                  // ── Customer section ──
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

                  // ── Cart section ──
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
                          'Your cart is empty.\nTap "Add Product" or "Scan QR" to add items.',
                      icon: Icons.shopping_cart_outlined,
                    )
                  else
                    ..._cart.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return _buildCartItemCard(idx, item);
                    }),
                  const SizedBox(height: 20),

                  // ── Payment section ──
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

                  // ── Checkout section ──
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

            // ── Bottom action bar ──
            // Using a custom layout to avoid overflow from multiple secondary buttons
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row: Scan QR + Add Product buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: _isProcessingScan
                                  ? null
                                  : _addFromScan,
                              icon: const Icon(Icons.qr_code_scanner, size: 18),
                              label: const Text('Scan QR'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.deepPurple,
                                side: BorderSide(
                                  color: Colors.deepPurple.shade200,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: _addProductManually,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Product'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.deepPurple,
                                side: BorderSide(
                                  color: Colors.deepPurple.shade200,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Bottom row: Complete Sale button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveSale,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline, size: 20),
                        label: Text(
                          _isSaving ? 'Processing...' : 'Complete Sale',
                        ),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a cart item card with quantity stepper (‑ / +) and remove button.
  /// The increment button is disabled/visually dimmed when max stock is reached.
  Widget _buildCartItemCard(int index, CartItem item) {
    final bool atMaxStock = item.quantity >= item.maxQuantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: product name + remove button
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _cart.removeAt(index)),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.close, size: 18, color: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Batch & price info row
            Row(
              children: [
                Icon(Icons.qr_code, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  item.batchCode,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: atMaxStock
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Avail: ${item.maxQuantity % 1 == 0 ? item.maxQuantity.toInt().toString() : item.maxQuantity.toString()}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: atMaxStock ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatAmount(item.sellingPrice),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Quantity stepper + subtotal
            Row(
              children: [
                // Decrement
                _quantityButton(
                  icon: Icons.remove,
                  onTap: () => _decrementQuantity(index),
                  color: item.quantity <= 1 ? Colors.red : Colors.deepPurple,
                ),
                const SizedBox(width: 10),
                // Quantity display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    item.quantity % 1 == 0
                        ? item.quantity.toInt().toString()
                        : item.quantity.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Increment — dimmed & disabled when at max stock
                _quantityButton(
                  icon: Icons.add,
                  onTap: atMaxStock ? null : () => _incrementQuantity(index),
                  color: atMaxStock ? Colors.grey : Colors.deepPurple,
                ),
                const Spacer(),
                // Subtotal
                Text(
                  _formatAmount(item.subtotal),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            // Show "Max reached" hint when at stock limit
            if (atMaxStock)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Max stock limit reached',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CART ITEM MODEL
// ─────────────────────────────────────────────────────────────

class CartItem {
  final String productId;
  final String productName;
  final String batchId;
  final String batchCode;
  final double quantity;
  final double sellingPrice;
  final double maxQuantity; // Maximum stock available in this batch
  double get subtotal => quantity * sellingPrice;
  CartItem({
    required this.productId,
    required this.productName,
    required this.batchId,
    required this.batchCode,
    required this.quantity,
    required this.sellingPrice,
    this.maxQuantity = 999, // Default high cap if not provided
  });
}
