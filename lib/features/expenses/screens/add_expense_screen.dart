import 'package:dukabase/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../../payment_methods/providers/payment_method_provider.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/constants/expense_categories.dart';

class AddExpenseScreen extends StatefulWidget {
  final ShopModel shop;
  const AddExpenseScreen({super.key, required this.shop});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = ExpenseCategories.all.first;
  String? _selectedPaymentMethodId;
  final _referenceController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _expenseDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load payment methods for this shop
    Future.microtask(() {
      Provider.of<PaymentMethodProvider>(context, listen: false)
          .loadPaymentMethods(widget.shop.id);
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _expenseDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPaymentMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method'), backgroundColor: Colors.red),
      );
      return;
    }
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await expenseProvider.recordExpense(
      shopId: widget.shop.id,
      description: _descriptionController.text.trim(),
      amount: amount,
      category: _selectedCategory,
      paymentMethodId: _selectedPaymentMethodId!,
      referenceNumber: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      expenseDate: _expenseDate,
      createdBy: authProvider.currentUser!.id,
    );
    setState(() => _isLoading = false);
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense recorded'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(expenseProvider.error ?? 'Failed'), backgroundColor: Colors.red),
      );
      expenseProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<PaymentMethodProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Record Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description *'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount *'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category *'),
                items: ExpenseCategories.all.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethodId,
                decoration: const InputDecoration(labelText: 'Payment Method *'),
                items: paymentProvider.methods.map((method) {
                  return DropdownMenuItem(
                    value: method.id,
                    child: Text('${method.name} (Balance: ${method.currentBalance.toStringAsFixed(2)})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedPaymentMethodId = val),
                validator: (v) => v == null ? 'Select payment method' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(labelText: 'Reference / Invoice # (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Expense Date'),
                subtitle: Text(_expenseDate.toLocal().toString().split(' ')[0]),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectDate,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveExpense,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Save Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}