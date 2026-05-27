import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/connectivity_helper.dart';
import '../../core/widgets/transaction_form_ui.dart';
import '../shops/providers/shop_provider.dart';
import '../auth/providers/auth_provider.dart';

class CreateShopScreen extends StatefulWidget {
  const CreateShopScreen({super.key});

  @override
  State<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends State<CreateShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedCurrency = 'TZS';
  final List<String> _currencies = ['TZS', 'USD', 'KES', 'NGN', 'EUR', 'GBP'];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createShop() async {
    if (!_formKey.currentState!.validate()) return;

    if (!await ConnectivityHelper.isOnline()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You need an internet connection to create a new shop. '
            'Connect to the internet and try again.',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);

    final success = await shopProvider.createShop(
      name: _nameController.text.trim(),
      ownerId: authProvider.currentUser!.id,
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      currency: _selectedCurrency,
    );

    setState(() => _isLoading = false);

    if (success) {
      // Force a refresh of shops (the stream will also update, but this is safe)
      shopProvider.loadUserShops(authProvider.currentUser!.id);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop created successfully')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shopProvider.error ?? 'Failed to create shop'),
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
      appBar: AppBar(title: const Text('Create New Shop')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          children: [
            TransactionFormUi.sectionHeader(
              icon: Icons.store_outlined,
              title: 'Shop details',
              subtitle: 'Basic information about your shop',
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
              onPressed: _isLoading ? null : _createShop,
              label: 'Create Shop',
              icon: _isLoading ? null : Icons.add_business_outlined,
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
