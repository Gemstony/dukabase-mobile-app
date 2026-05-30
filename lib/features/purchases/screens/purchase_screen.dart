import 'package:dukabase/core/utils/currency_formatter.dart';
import 'package:dukabase/core/utils/qr_code_helper.dart';
import 'package:dukabase/core/widgets/transaction_form_ui.dart';
import 'package:dukabase/features/payment_methods/providers/payment_method_provider.dart';
import 'package:dukabase/features/purchases/screens/add_purchase_from_scan_screen.dart';
import 'package:dukabase/features/sales/screens/barcode_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/purchase_provider.dart';
import '../../suppliers/providers/supplier_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/models/supplier_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/product_service.dart';
import 'purchases_list_screen.dart';

// ─────────────────────────────────────────────────────────────
// BATCH CODE GENERATOR
// ─────────────────────────────────────────────────────────────

String generateBatchCode({required int sequence}) {
  final date = DateFormat('yyyyMMdd').format(DateTime.now());
  return 'BT$date${sequence.toString().padLeft(3, '0')}';
}

// ─────────────────────────────────────────────────────────────
// PURCHASE SCREEN (MAIN)
// ─────────────────────────────────────────────────────────────

class PurchaseScreen extends StatefulWidget {
  final ShopModel shop;
  const PurchaseScreen({super.key, required this.shop});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  String? _selectedPaymentMethodId;
  SupplierModel? _selectedSupplier;
  double _paidAmount = 0;

  final List<PurchaseItem> _items = [];
  final TextEditingController _paidController = TextEditingController();
  bool _isProcessingScan = false;
  bool _isSaving = false;
  bool _isDisposed = false; //  added disposal flag

  @override
  void initState() {
    super.initState();
    // Load data after first frame to avoid race conditions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
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
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _paidController.dispose();
    super.dispose();
  }

  double get _totalAmount => _items.fold(0, (sum, item) => sum + item.subtotal);

  // ─────────────────────────────────────────────────────────────
  // SCAN QR CODE → ADD PURCHASE ITEM
  // ─────────────────────────────────────────────────────────────

  Future<void> _addFromScan() async {
    if (_isProcessingScan || _isDisposed) return;
    setState(() => _isProcessingScan = true);

    try {
      final scannedValue = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
      );
      if (!mounted || _isDisposed) return;
      if (scannedValue == null || scannedValue.isEmpty) return;

      final decoded = QRCodeHelper.decodeBatchData(scannedValue);
      if (decoded == null) {
        _showSnackBar('Invalid QR code format.');
        return;
      }
      if (decoded.shopId != widget.shop.id) {
        _showSnackBar('This QR code belongs to a different shop.');
        return;
      }

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

      final batches = await _productService.getActiveBatches(
        widget.shop.id,
        product.id,
      );
      if (!mounted || _isDisposed) return;

      final existingBatch = batches
          .where((b) => b.batchCode == decoded.batchCode)
          .firstOrNull;

      final result = await Navigator.push<PurchaseItem>(
        context,
        MaterialPageRoute(
          builder: (_) => AddPurchaseFromScanScreen(
            product: product,
            scannedBatchCode: decoded.batchCode,
            existingSellingPrice: existingBatch?.sellingPrice,
          ),
        ),
      );

      if (result != null && mounted && !_isDisposed) {
        // No need for addPostFrameCallback - the new screen is completely separate
        setState(() => _items.add(result));
        _showSnackBar('${product.name} added to purchase', isError: false);
      }
    } catch (e) {
      if (mounted && !_isDisposed) _showSnackBar('Scan error: $e');
    } finally {
      if (mounted && !_isDisposed) setState(() => _isProcessingScan = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // MANUAL ADD ITEM
  // ─────────────────────────────────────────────────────────────

  Future<void> _addItemManually() async {
    if (_isDisposed) return;
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    if (productProvider.products.isEmpty) {
      _showSnackBar('No products available. Create a product first.');
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPurchaseItemScreen(
          products: productProvider.products,
          existingItemCount: _items.length,
        ),
      ),
    );
    if (result != null && result is PurchaseItem && mounted && !_isDisposed) {
      setState(() => _items.add(result));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SAVE PURCHASE
  // ─────────────────────────────────────────────────────────────

  Future<void> _savePurchase() async {
    if (_isSaving || _isDisposed) return;

    if (_selectedSupplier == null) {
      _showSnackBar('Please select a supplier');
      return;
    }
    if (_items.isEmpty) {
      _showSnackBar('Add at least one item');
      return;
    }
    if (_selectedPaymentMethodId == null) {
      _showSnackBar('Please select a payment method');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    if (_paidAmount < _totalAmount) {
      final confirmed = await _showShortPaymentConfirmation();
      if (confirmed != true) return;
    }

    setState(() => _isSaving = true);

    try {
      final purchaseProvider = Provider.of<PurchaseProvider>(
        context,
        listen: false,
      );
      final result = await purchaseProvider.recordPurchase(
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

      if (!mounted || _isDisposed) return;

      if (result.success) {
        final message = result.pendingSync
            ? 'Purchase saved offline — will sync when you\'re back online'
            : 'Purchase recorded successfully';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PurchasesListScreen(shop: widget.shop, successMessage: message),
          ),
        );
      } else {
        _showSnackBar(purchaseProvider.error ?? 'Failed to record purchase');
        purchaseProvider.clearError();
      }
    } catch (e) {
      if (mounted && !_isDisposed) _showSnackBar('Purchase error: $e');
    } finally {
      if (mounted && !_isDisposed) setState(() => _isSaving = false);
    }
  }

  Future<bool?> _showShortPaymentConfirmation() async {
    final unpaid = _totalAmount - _paidAmount;
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
              'The amount paid is less than the total purchase amount.',
            ),
            const SizedBox(height: 16),
            _confirmationRow('Total', _formatAmount(_totalAmount)),
            const SizedBox(height: 6),
            _confirmationRow('Paid', _formatAmount(_paidAmount)),
            const SizedBox(height: 6),
            _confirmationRow(
              'Balance',
              _formatAmount(unpaid),
              valueColor: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'The balance will be recorded as outstanding to the supplier.',
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
            child: const Text('Confirm Purchase'),
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

  String _formatAmount(double amount) =>
      CurrencyFormatter.format(amount, widget.shop.currency);

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted || _isDisposed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final supplierProvider = Provider.of<SupplierProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final paymentProvider = Provider.of<PaymentMethodProvider>(context);
    final balance = _totalAmount - _paidAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Purchase'),
        actions: [
          if (_items.isNotEmpty)
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
                    '${_items.length} item${_items.length == 1 ? '' : 's'}',
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
                    icon: Icons.local_shipping_outlined,
                    title: 'Supplier & payment',
                    subtitle: 'Who you bought from and how you paid',
                  ),
                  TransactionFormUi.formCard(
                    children: [
                      DropdownButtonFormField<SupplierModel>(
                        decoration: TransactionFormUi.fieldDecoration(
                          context,
                          label: 'Supplier *',
                          prefixIcon: Icons.store_outlined,
                        ),
                        items: supplierProvider.suppliers
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedSupplier = value),
                        validator: (v) => v == null ? 'Select supplier' : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        decoration: TransactionFormUi.fieldDecoration(
                          context,
                          label: 'Payment Method *',
                          prefixIcon: Icons.account_balance_wallet_outlined,
                        ),
                        initialValue: _selectedPaymentMethodId,
                        items: paymentProvider.methods
                            .map(
                              (method) => DropdownMenuItem(
                                value: method.id,
                                child: Text(
                                  '${method.name} · ${_formatAmount(method.currentBalance)}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedPaymentMethodId = val),
                        validator: (v) =>
                            v == null ? 'Select payment method' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TransactionFormUi.sectionHeader(
                    icon: Icons.shopping_basket_outlined,
                    title: 'Purchase items',
                    subtitle: productProvider.products.isEmpty
                        ? 'Add products to your shop first'
                        : 'Scan QR or tap Add Item below',
                  ),
                  if (_items.isEmpty)
                    TransactionFormUi.emptyItemsState(
                      message:
                          'No items yet.\nScan a batch QR code or tap "Add Item" to include stock.',
                      icon: Icons.add_shopping_cart_outlined,
                    )
                  else
                    ..._items.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return TransactionFormUi.lineItemCard(
                        title: item.productName,
                        trailingAmount: _formatAmount(item.subtotal),
                        chips: [
                          'Batch ${item.batchCode}',
                          'Qty ${item.quantity}',
                          'Cost ${_formatAmount(item.costPrice)}',
                          'Sell ${_formatAmount(item.sellingPrice)}',
                        ],
                        onRemove: () => setState(() => _items.removeAt(idx)),
                      );
                    }),
                  const SizedBox(height: 20),
                  TransactionFormUi.sectionHeader(
                    icon: Icons.payments_outlined,
                    title: 'Payment details',
                  ),
                  TransactionFormUi.paymentSummaryCard(
                    totalLabel: 'Total amount',
                    totalValue: _formatAmount(_totalAmount),
                    secondaryLabel: balance > 0
                        ? 'Outstanding balance'
                        : 'Fully paid',
                    secondaryValue: _formatAmount(balance.abs()),
                    secondaryColor: balance > 0
                        ? Colors.orange.shade200
                        : Colors.greenAccent.shade100,
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
                          hint: 'Enter amount paid now',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) {
                          _paidAmount = double.tryParse(value) ?? 0;
                          setState(() {});
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null)
                            return 'Invalid number';
                          return null;
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
                              onPressed: _addItemManually,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Item'),
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
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _savePurchase,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined, size: 20),
                        label: Text(_isSaving ? 'Saving...' : 'Save Purchase'),
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
}

// ─────────────────────────────────────────────────────────────
// PURCHASE ITEM MODEL (unchanged)
// ─────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────
// ADD PURCHASE ITEM SCREEN (unchanged)
// ─────────────────────────────────────────────────────────────

class AddPurchaseItemScreen extends StatefulWidget {
  final List<ProductModel> products;
  final int existingItemCount;
  const AddPurchaseItemScreen({
    super.key,
    required this.products,
    this.existingItemCount = 0,
  });

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
  void initState() {
    super.initState();
    _batchCodeController.text = generateBatchCode(
      sequence: widget.existingItemCount + 1,
    );
  }

  @override
  void dispose() {
    _batchCodeController.dispose();
    _quantityController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  void _save() {
    if (_selectedProduct == null) {
      _showError('Please select a product');
      return;
    }
    if (_batchCodeController.text.isEmpty) {
      _showError('Batch code is required');
      return;
    }
    final quantity = double.tryParse(_quantityController.text);
    final costPrice = double.tryParse(_costPriceController.text);
    final sellingPrice = double.tryParse(_sellingPriceController.text);
    if (quantity == null || quantity <= 0) {
      _showError('Enter a valid quantity');
      return;
    }
    if (costPrice == null || costPrice <= 0) {
      _showError('Enter a valid cost price');
      return;
    }
    if (sellingPrice == null || sellingPrice <= 0) {
      _showError('Enter a valid selling price');
      return;
    }

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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _onProductSelected(ProductModel? product) {
    setState(() {
      _selectedProduct = product;
      if (product != null) {
        _sellingPriceController.text = product.defaultSellingPrice.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TransactionFormUi.sectionHeader(
                icon: Icons.inventory_2_outlined,
                title: 'Product details',
                subtitle: 'Select product and batch information',
              ),
              TransactionFormUi.formCard(
                children: [
                  DropdownButtonFormField<ProductModel>(
                    decoration: TransactionFormUi.fieldDecoration(
                      context,
                      label: 'Product *',
                      prefixIcon: Icons.category_outlined,
                    ),
                    items: widget.products
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              p.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _onProductSelected,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _batchCodeController,
                    decoration: TransactionFormUi.fieldDecoration(
                      context,
                      label: 'Batch Code *',
                      prefixIcon: Icons.qr_code_2_outlined,
                    ),
                    readOnly: false,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Auto-generated batch code — you can edit it',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TransactionFormUi.sectionHeader(
                icon: Icons.calculate_outlined,
                title: 'Quantity & pricing',
              ),
              TransactionFormUi.formCard(
                children: [
                  TextFormField(
                    controller: _quantityController,
                    decoration: TransactionFormUi.fieldDecoration(
                      context,
                      label: 'Quantity *',
                      prefixIcon: Icons.numbers_outlined,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _costPriceController,
                          decoration: TransactionFormUi.fieldDecoration(
                            context,
                            label: 'Cost Price *',
                            prefixIcon: Icons.arrow_downward,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _sellingPriceController,
                          decoration: TransactionFormUi.fieldDecoration(
                            context,
                            label: 'Sell Price *',
                            prefixIcon: Icons.arrow_upward,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TransactionFormUi.sectionHeader(
                icon: Icons.event_outlined,
                title: 'Expiry (optional)',
              ),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (date != null) {
                    setState(() => _expiryDate = date);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: TransactionFormUi.formCard(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          color: Colors.deepPurple.shade300,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Expiry date',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _expiryDate == null
                                    ? 'Tap to set expiry date'
                                    : DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(_expiryDate!),
                                style: TextStyle(
                                  color: _expiryDate == null
                                      ? Colors.grey.shade600
                                      : Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TransactionFormUi.primaryButton(
                onPressed: _save,
                label: 'Add to Purchase',
                icon: Icons.add_shopping_cart,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
