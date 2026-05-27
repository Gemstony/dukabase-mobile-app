import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/transaction_form_ui.dart';
import '../providers/supplier_provider.dart';
import '../../../core/models/shop_model.dart';

class AddSupplierScreen extends StatefulWidget {
  final ShopModel shop;
  const AddSupplierScreen({super.key, required this.shop});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final provider = Provider.of<SupplierProvider>(context, listen: false);
    final result = await provider.createSupplier(
      shopId: widget.shop.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      openingBalance: double.tryParse(_balanceController.text) ?? 0,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.success) {
      final message = result.pendingSync
          ? 'Supplier saved offline — will sync when you\'re back online'
          : 'Supplier added successfully';
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
      appBar: AppBar(title: const Text('Add Supplier')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          children: [
            TransactionFormUi.sectionHeader(
              icon: Icons.local_shipping_outlined,
              title: 'Supplier details',
              subtitle: 'Contact information for the supplier',
            ),
            TransactionFormUi.formCard(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'Supplier Name *',
                    prefixIcon: Icons.person_outlined,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'Phone Number *',
                    prefixIcon: Icons.phone_outlined,
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'Email (optional)',
                    prefixIcon: Icons.email_outlined,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'Address (optional)',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TransactionFormUi.sectionHeader(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Financial information',
              subtitle: 'Opening balance for this supplier',
            ),
            TransactionFormUi.formCard(
              children: [
                TextFormField(
                  controller: _balanceController,
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'Opening Balance (optional)',
                    prefixIcon: Icons.paid_outlined,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            const SizedBox(height: 24),
            TransactionFormUi.primaryButton(
              onPressed: _isLoading ? null : _saveSupplier,
              label: 'Save Supplier',
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
