import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/transaction_form_ui.dart';
import '../providers/payment_method_provider.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/models/payment_method_model.dart';

class AddPaymentMethodScreen extends StatefulWidget {
  final ShopModel shop;
  const AddPaymentMethodScreen({super.key, required this.shop});

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  PaymentMethodType _selectedType = PaymentMethodType.cash;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _saveMethod() async {
    if (!_formKey.currentState!.validate()) return;
    final balance = double.tryParse(_balanceController.text);
    if (balance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid balance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final provider = Provider.of<PaymentMethodProvider>(context, listen: false);
    final result = await provider.createPaymentMethod(
      shopId: widget.shop.id,
      name: _nameController.text.trim(),
      type: _selectedType,
      initialBalance: balance,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.success) {
      final message = result.pendingSync
          ? 'Payment method saved offline — will sync when you\'re back online'
          : 'Payment method added successfully';
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
      appBar: AppBar(title: const Text('Add Payment Method')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          children: [
            TransactionFormUi.sectionHeader(
              icon: Icons.payment_outlined,
              title: 'Payment Method Details',
              subtitle: 'Configure your payment method',
            ),
            TransactionFormUi.formCard(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'Name *',
                    prefixIcon: Icons.payments_outlined,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<PaymentMethodType>(
                  initialValue: _selectedType,
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'Type *',
                    prefixIcon: Icons.category_outlined,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: PaymentMethodType.cash,
                      child: Text('Cash'),
                    ),
                    DropdownMenuItem(
                      value: PaymentMethodType.bank,
                      child: Text('Bank Account'),
                    ),
                    DropdownMenuItem(
                      value: PaymentMethodType.mobile_money,
                      child: Text('Mobile Money'),
                    ),
                    DropdownMenuItem(
                      value: PaymentMethodType.other,
                      child: Text('Other'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedType = value);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _balanceController,
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'Initial Balance *',
                    prefixIcon: Icons.attach_money_outlined,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            TransactionFormUi.primaryButton(
              onPressed: _isLoading ? null : _saveMethod,
              label: 'Save Payment Method',
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