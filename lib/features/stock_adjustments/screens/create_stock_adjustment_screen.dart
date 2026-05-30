import 'package:dukabase/core/utils/connectivity_helper.dart';
import 'package:dukabase/core/utils/qr_code_helper.dart';
import 'package:dukabase/core/widgets/transaction_form_ui.dart';
import 'package:dukabase/features/auth/providers/auth_provider.dart';
import 'package:dukabase/features/sales/screens/barcode_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_adjustment_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/batch_model.dart';
import '../../../core/services/product_service.dart';

class CreateStockAdjustmentScreen extends StatefulWidget {
  final ShopModel shop;
  const CreateStockAdjustmentScreen({super.key, required this.shop});

  @override
  State<CreateStockAdjustmentScreen> createState() =>
      _CreateStockAdjustmentScreenState();
}

class _CreateStockAdjustmentScreenState
    extends State<CreateStockAdjustmentScreen> {
  final _productService = ProductService();
  final _formKey = GlobalKey<FormState>();
  ProductModel? _selectedProduct;
  BatchModel? _selectedBatch;
  String _selectedReason = 'damage';
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;
  bool _isProcessingScan = false;

  final List<String> _reasons = [
    'damage',
    'theft',
    'expiry',
    'correction',
    'return',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ProductProvider>(
        context,
        listen: false,
      ).loadProducts(widget.shop.id);
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // QR CODE SCANNING – AUTO POPULATE PRODUCT & BATCH
  // ─────────────────────────────────────────────────────────────

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
        _showSnackBar('Invalid QR code format. Expected a batch QR code.');
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

      // 5. Find the batch with matching batchCode (even zero stock allowed? adjustment may be negative)
      final batches = await _productService.getActiveBatches(
        widget.shop.id,
        product.id,
      );
      final batch = batches
          .where((b) => b.batchCode == decoded.batchCode)
          .firstOrNull;

      if (batch == null) {
        _showSnackBar(
          'Batch "${decoded.batchCode}" for ${product.name} was not found.',
        );
        return;
      }

      // 6. Populate form with scanned product and batch
      setState(() {
        _selectedProduct = product;
        _selectedBatch = batch;
      });

      _showSnackBar(
        'Scanned: ${product.name} (Batch ${batch.batchCode})',
        isError: false,
      );
    } catch (e) {
      _showSnackBar('Scan error: $e');
    } finally {
      if (mounted) setState(() => _isProcessingScan = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // MANUAL PRODUCT & BATCH SELECTION (unchanged)
  // ─────────────────────────────────────────────────────────────

  Future<void> _selectProduct() async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    if (productProvider.products.isEmpty) {
      _showSnackBar('No products available');
      return;
    }
    final product = await showDialog<ProductModel>(
      context: context,
      builder: (ctx) => TransactionFormUi.styledDialog(
        title: 'Select Product',
        icon: Icons.inventory_2_outlined,
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: productProvider.products.length,
            itemBuilder: (_, i) {
              final p = productProvider.products[i];
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
    if (product != null) {
      setState(() {
        _selectedProduct = product;
        _selectedBatch = null;
      });
      await _loadBatches(product.id);
    }
  }

  Future<void> _loadBatches(String productId) async {
    try {
      final batches = await _productService.getActiveBatches(
        widget.shop.id,
        productId,
      );
      if (!mounted) return;
      if (batches.isEmpty) {
        final offline = !await ConnectivityHelper.isOnline();
        _showSnackBar(
          offline
              ? 'No batch data for this product on this device. '
                  'Open the shop while online once, or add stock first.'
              : 'No active batches for this product',
        );
        return;
      }

      final batch = await showDialog<BatchModel>(
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
                      'Qty ${b.quantity} · Cost ${b.costPrice}$expiry',
                  icon: Icons.qr_code_2_outlined,
                  onTap: () => Navigator.pop(ctx, b),
                );
              },
            ),
          ),
        ),
      );

      if (batch != null) {
        setState(() => _selectedBatch = batch);
      }
    } catch (e) {
      _showSnackBar('Failed to load batches: $e');
    }
  }

  Future<void> _saveAdjustment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      _showSnackBar('Select a product');
      return;
    }
    if (_selectedBatch == null) {
      _showSnackBar('Select a batch');
      return;
    }
    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null) {
      _showSnackBar('Invalid quantity');
      return;
    }

    setState(() => _isLoading = true);
    final provider = Provider.of<StockAdjustmentProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await provider.recordAdjustment(
      shopId: widget.shop.id,
      productId: _selectedProduct!.id,
      batchId: _selectedBatch!.id,
      reason: _selectedReason,
      quantityChange: quantity,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdBy: authProvider.currentUser!.id,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.success) {
      final message = result.pendingSync
          ? 'Adjustment saved offline — will sync when you\'re back online'
          : 'Stock adjustment recorded successfully';
      Navigator.pop(context, message);
    } else {
      _showSnackBar(provider.error ?? 'Failed');
      provider.clearError();
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Adjustment'),
        actions: [
          // Scan QR button in the app bar
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR code',
            onPressed: _isProcessingScan ? null : _addFromScan,
          ),
          if (_selectedProduct != null)
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
                    _selectedProduct!.name,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // ── Product & Batch section with Scan hint ──
            TransactionFormUi.sectionHeader(
              icon: Icons.inventory_2_outlined,
              title: 'Product & Batch',
              subtitle: _selectedProduct == null
                  ? 'Select a product manually or tap the QR icon to scan a batch code'
                  : 'Adjusting stock for ${_selectedProduct!.name}',
            ),
            TransactionFormUi.formCard(
              children: [
                // Product selection (manual)
                InkWell(
                  onTap: _selectProduct,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 20,
                          color: Colors.deepPurple[300],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Product',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedProduct != null
                                    ? '${_selectedProduct!.name} (Stock: ${_selectedProduct!.currentStock} ${_selectedProduct!.unit})'
                                    : 'Tap to select product *',
                                style: TextStyle(
                                  fontWeight: _selectedProduct != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: _selectedProduct != null
                                      ? Colors.deepPurple
                                      : Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selectedProduct != null) ...[
                  const SizedBox(height: 12),
                  // Batch selection (manual)
                  InkWell(
                    onTap: () => _loadBatches(_selectedProduct!.id),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.qr_code_2_outlined,
                            size: 20,
                            color: Colors.deepPurple[300],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Batch',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedBatch != null
                                      ? '${_selectedBatch!.batchCode} | Qty: ${_selectedBatch!.quantity}'
                                      : 'Tap to select batch *',
                                  style: TextStyle(
                                    fontWeight: _selectedBatch != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: _selectedBatch != null
                                        ? Colors.deepPurple
                                        : Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // ── Reason & Quantity section ──
            TransactionFormUi.sectionHeader(
              icon: Icons.tune_outlined,
              title: 'Adjustment Details',
              subtitle: 'Reason for the adjustment and quantity change',
            ),
            TransactionFormUi.formCard(
              children: [
                DropdownButtonFormField<String>(
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'Reason *',
                    prefixIcon: Icons.report_problem_outlined,
                  ),
                  initialValue: _selectedReason,
                  items: _reasons.map((r) {
                    return DropdownMenuItem(
                      value: r,
                      child: Text(r[0].toUpperCase() + r.substring(1)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedReason = val);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _quantityController,
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'Quantity Change *',
                    prefixIcon: Icons.numbers_outlined,
                    hint: 'Positive = add, Negative = remove (e.g. 5 or -3)',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final qty = double.tryParse(v);
                    if (qty == null) return 'Invalid number';
                    if (qty == 0) return 'Quantity cannot be zero';
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Note section ──
            TransactionFormUi.sectionHeader(
              icon: Icons.notes_outlined,
              title: 'Note (optional)',
              subtitle: 'Add any additional information',
            ),
            TransactionFormUi.formCard(
              children: [
                TextFormField(
                  controller: _noteController,
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'Note',
                    prefixIcon: Icons.edit_note_outlined,
                    hint: 'Describe the reason for adjustment...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Batch summary (if batch selected) ──
            if (_selectedBatch != null) ...[
              TransactionFormUi.sectionHeader(
                icon: Icons.info_outline,
                title: 'Batch Summary',
              ),
              TransactionFormUi.paymentSummaryCard(
                totalLabel: 'Current Batch Qty',
                totalValue: _selectedBatch!.quantity.toString(),
                secondaryLabel: 'Selected Batch',
                secondaryValue: _selectedBatch!.batchCode,
              ),
              const SizedBox(height: 20),
            ],

            // ── Save Button ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveAdjustment,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 20),
                label: Text(_isLoading ? 'Saving...' : 'Save Adjustment'),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}