import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/shop_model.dart';
import '../providers/shop_provider.dart';

class EditShopScreen extends StatefulWidget {
  final ShopModel shop;
  const EditShopScreen({super.key, required this.shop});

  @override
  State<EditShopScreen> createState() => _EditShopScreenState();
}

class _EditShopScreenState extends State<EditShopScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late String _selectedCurrency;
  bool _isLoading = false;

  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'TZS', 'KES', 'NGN'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shop.name);
    _addressController = TextEditingController(text: widget.shop.address ?? '');
    _phoneController = TextEditingController(text: widget.shop.phone ?? '');
    _selectedCurrency = widget.shop.currency;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final success = await shopProvider.updateShop(
      shopId: widget.shop.id,
      name: _nameController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      currency: _selectedCurrency,
    );
    setState(() => _isLoading = false);
    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop updated'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shopProvider.error ?? 'Update failed'), backgroundColor: Colors.red),
      );
      shopProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Shop')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Shop Name *'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCurrency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCurrency = val!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}