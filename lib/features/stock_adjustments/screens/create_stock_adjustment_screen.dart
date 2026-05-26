import 'package:dukabase/core/utils/connectivity_helper.dart';
import 'package:dukabase/features/auth/providers/auth_provider.dart';
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

  Future<void> _selectProduct() async {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    if (productProvider.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No products available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final product = await showDialog<ProductModel>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Product'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: productProvider.products.length,
            itemBuilder: (_, i) {
              final p = productProvider.products[i];
              return ListTile(
                title: Text(p.name),
                subtitle: Text('Stock: ${p.currentStock} ${p.unit}'),
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
        _selectedBatch = null; // reset batch when product changes
      });
      // Load batches for this product
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              offline
                  ? 'No batch data for this product on this device. '
                        'Open the shop while online once, or add stock first.'
                  : 'No active batches for this product',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final batch = await showDialog<BatchModel>(
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
                    'Quantity: ${b.quantity} | Cost: ${b.costPrice}',
                  ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load batches: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveAdjustment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a product'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedBatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a batch'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid quantity'),
          backgroundColor: Colors.red,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed'),
          backgroundColor: Colors.red,
        ),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Adjustment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Product selection
              ListTile(
                title: const Text('Product'),
                subtitle: Text(
                  _selectedProduct != null
                      ? '${_selectedProduct!.name} (Stock: ${_selectedProduct!.currentStock})'
                      : 'Not selected',
                ),
                trailing: ElevatedButton(
                  onPressed: _selectProduct,
                  child: const Text('Select'),
                ),
              ),
              const SizedBox(height: 12),
              // Batch selection (enabled only after product selected)
              if (_selectedProduct != null)
                ListTile(
                  title: const Text('Batch'),
                  subtitle: Text(
                    _selectedBatch != null
                        ? 'Batch: ${_selectedBatch!.batchCode} | Qty: ${_selectedBatch!.quantity}'
                        : 'Not selected',
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _loadBatches(_selectedProduct!.id),
                    child: const Text('Select'),
                  ),
                ),
              const SizedBox(height: 12),
              // Reason
              DropdownButtonFormField<String>(
                initialValue: _selectedReason,
                decoration: const InputDecoration(labelText: 'Reason *'),
                items: _reasons
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(r.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedReason = val!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,

                decoration: const InputDecoration(
                  labelText:
                      'Quantity Change (positive = add, negative = remove) *',
                  hintText: 'e.g., 5 or -3',
                ),

                keyboardType: TextInputType.text,

                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Required';
                  }

                  final qty = double.tryParse(v);

                  if (qty == null) {
                    return 'Invalid number';
                  }

                  if (qty == 0) {
                    return 'Quantity cannot be zero';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveAdjustment,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Save Adjustment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
