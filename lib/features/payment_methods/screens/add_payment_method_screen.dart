import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        const SnackBar(content: Text('Invalid balance'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    final provider = Provider.of<PaymentMethodProvider>(context, listen: false);
    final success = await provider.createPaymentMethod(
      shopId: widget.shop.id,
      name: _nameController.text.trim(),
      type: _selectedType,
      initialBalance: balance,
    );
    setState(() => _isLoading = false);
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment method added'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed'), backgroundColor: Colors.red),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Payment Method')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PaymentMethodType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Type *'),
                items: const [
                  DropdownMenuItem(value: PaymentMethodType.cash, child: Text('Cash')),
                  DropdownMenuItem(value: PaymentMethodType.bank, child: Text('Bank Account')),
                  DropdownMenuItem(value: PaymentMethodType.mobile_money, child: Text('Mobile Money')),
                  DropdownMenuItem(value: PaymentMethodType.other, child: Text('Other')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _balanceController,
                decoration: const InputDecoration(labelText: 'Initial Balance *'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveMethod,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Save Payment Method'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}