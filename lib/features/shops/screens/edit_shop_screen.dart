import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/widgets/transaction_form_ui.dart';
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

  final List<String> _currencies = ['TZS', 'USD', 'KES', 'NGN', 'EUR', 'GBP'];

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
    final result = await shopProvider.updateShop(
      shopId: widget.shop.id,
      name: _nameController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      currency: _selectedCurrency,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.success) {
      final message = result.pendingSync
          ? 'Shop saved offline — will sync when you\'re back online'
          : 'Shop updated successfully';
      Navigator.pop(context, message);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shopProvider.error ?? 'Update failed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      shopProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Shop')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          children: [
            TransactionFormUi.sectionHeader(
              icon: Icons.store_outlined,
              title: 'Shop details',
              subtitle: 'Update your shop information',
            ),
            TransactionFormUi.formCard(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'Shop Name *',
                    prefixIcon: Icons.business_outlined,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
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
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'Phone (optional)',
                    prefixIcon: Icons.phone_outlined,
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCurrency,
                  decoration: TransactionFormUi.fieldDecoration(
                    context,
                    label: 'Currency',
                    prefixIcon: Icons.payments_outlined,
                  ),
                  items: _currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setState(() {
                    if (val != null) _selectedCurrency = val;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TransactionFormUi.primaryButton(
              onPressed: _isLoading ? null : _save,
              label: 'Save Changes',
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
