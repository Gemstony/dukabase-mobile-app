import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/transaction_form_ui.dart';
import '../providers/product_provider.dart';
import '../../../core/models/shop_model.dart';

class AddProductScreen extends StatefulWidget {
  final ShopModel shop;
  const AddProductScreen({super.key, required this.shop});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _unitController = TextEditingController();
  final _priceController = TextEditingController();
  final _alertController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _alertController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final result = await provider.createProduct(
      shopId: widget.shop.id,
      name: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      unit: _unitController.text.trim(),
      defaultSellingPrice: double.parse(_priceController.text),
      lowStockAlert: double.parse(_alertController.text),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.success) {
      final message = result.pendingSync
          ? 'Product saved offline — will sync when you\'re back online'
          : 'Product added successfully';
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
      appBar: AppBar(title: const Text('Add Product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          children: [
            TransactionFormUi.sectionHeader(
              icon: Icons.inventory_2_outlined,
              title: 'Product information',
              subtitle: 'Basic details about the product',
            ),
            TransactionFormUi.formCard(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'Product Name *',
                    prefixIcon: Icons.label_outlined,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _skuController,
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'SKU / Barcode *',
                    prefixIcon: Icons.qr_code_2_outlined,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _unitController,
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'Unit (e.g., pcs, kg) *',
                    prefixIcon: Icons.straighten_outlined,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
            const SizedBox(height: 20),
            TransactionFormUi.sectionHeader(
              icon: Icons.sell_outlined,
              title: 'Pricing & alerts',
              subtitle: 'Set selling price and stock thresholds',
            ),
            TransactionFormUi.formCard(
              children: [
                TextFormField(
                  controller: _priceController,
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'Default Selling Price *',
                    prefixIcon: Icons.attach_money_outlined,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _alertController,
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'Low Stock Alert (quantity) *',
                    prefixIcon: Icons.warning_amber_outlined,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            TransactionFormUi.primaryButton(
              onPressed: _isLoading ? null : _saveProduct,
              label: 'Save Product',
              icon: _isLoading ? null : Icons.save_outlined,
            ),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
