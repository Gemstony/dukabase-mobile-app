import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/transaction_form_ui.dart';
import '../providers/customer_provider.dart';
import '../../../core/models/shop_model.dart';

class AddCustomerScreen extends StatefulWidget {
  final ShopModel shop;
  const AddCustomerScreen({super.key, required this.shop});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  bool _isLoading = false;

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final provider = Provider.of<CustomerProvider>(context, listen: false);
    final result = await provider.createCustomer(
      shopId: widget.shop.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      openingBalance: double.tryParse(_balanceController.text) ?? 0,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.success) {
      final message = result.pendingSync
          ? 'Customer saved offline — will sync when you\'re back online'
          : 'Customer added successfully';
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
      appBar: AppBar(title: const Text('Add Customer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          children: [
            TransactionFormUi.sectionHeader(
              icon: Icons.person_outline,
              title: 'Customer details',
              subtitle: 'Contact information for the customer',
            ),
            TransactionFormUi.formCard(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'Customer Name *',
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
              ],
            ),
            const SizedBox(height: 20),
            TransactionFormUi.sectionHeader(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Financial information',
              subtitle: 'Opening balance for this customer',
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
              onPressed: _isLoading ? null : _saveCustomer,
              label: 'Save Customer',
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
