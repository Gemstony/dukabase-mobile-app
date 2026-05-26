import 'package:dukabase/core/utils/connectivity_helper.dart';
import 'package:dukabase/features/auth/providers/auth_provider.dart';
import 'package:dukabase/features/invitations/screens/owner_invitations_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/shop_model.dart';
import '../shops/providers/shop_provider.dart';
import '../staff/screens/staff_list_screen.dart'; // adjust import
import '../../features/backup/screens/backup_screen.dart';
import '../shops/screens/edit_shop_screen.dart';

class ShopDetailScreen extends StatefulWidget {
  final ShopModel shop;
  const ShopDetailScreen({super.key, required this.shop});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  late ShopModel _shop;

  @override
  void initState() {
    super.initState();
    _shop = widget.shop;
    if (!_shop.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _exitIfShopInactive());
    }
  }

  void _exitIfShopInactive() {
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This shop has been deactivated'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _refresh() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    if (userId != null) {
      shopProvider.loadUserShops(userId);
    }
    final refreshed = await shopProvider.getShopById(_shop.id);
    if (!mounted) return;
    if (refreshed != null) {
      setState(() => _shop = refreshed);
    } else {
      _exitIfShopInactive();
    }
  }

  Future<void> _editShop() async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => EditShopScreen(shop: _shop)),
    );
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _refresh();
  }

  Future<String?> _promptDeletePassword() {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DeleteShopPasswordDialog(shopName: _shop.name),
    );
  }

  void _dismissLoadingDialog() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _deleteShop() async {
    if (!_shop.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This shop is already deactivated'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!await ConnectivityHelper.isOnline()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'An internet connection is required to verify your password '
            'and delete a shop.',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final password = await _promptDeletePassword();
    if (!mounted || password == null || password.isEmpty) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    String? successMessage;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final verifyResult = await authProvider.verifyPassword(password);

      if (!mounted) return;
      if (!verifyResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              verifyResult.error ?? 'Password verification failed',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final shopProvider = Provider.of<ShopProvider>(context, listen: false);
      final result = await shopProvider.deleteShop(_shop.id);

      if (!mounted) return;

      if (result.success) {
        successMessage = result.pendingSync
            ? 'Shop deactivation saved offline — will sync when you\'re back online'
            : 'Shop deleted successfully';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(shopProvider.error ?? 'Delete failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        shopProvider.clearError();
      }
    } finally {
      _dismissLoadingDialog();
    }

    if (!mounted || successMessage == null) return;
    Navigator.pop(context, successMessage);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context).currentUser?.id;
    final isOwner = _shop.ownerId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(_shop.name),
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _editShop();
                if (value == 'delete') _deleteShop();
                if (value == 'backup') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BackupScreen(shop: _shop),
                    ),
                  );
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Shop')),
                const PopupMenuItem(
                  value: 'backup',
                  child: Text('Backup & Restore'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete Shop',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shop Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      _infoRow('Name', _shop.name),
                      if (_shop.address != null)
                        _infoRow('Address', _shop.address!),
                      if (_shop.phone != null) _infoRow('Phone', _shop.phone!),
                      _infoRow('Currency', _shop.currency),
                      _infoRow('Owner ID', _shop.ownerId),
                      _infoRow(
                        'Created',
                        DateFormat('dd MMM yyyy').format(_shop.createdAt),
                      ),
                      _infoRow(
                        'Status',
                        _shop.isActive ? 'Active' : 'Inactive',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Quick Actions Card
              if (isOwner)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            if (isOwner)
                              ElevatedButton.icon(
                                onPressed: _editShop,
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit Details'),
                              ),
                            if (isOwner)
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          OwnerInvitationsScreen(shop: _shop),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.mail_outline),
                                label: const Text('View Invitations'),
                              ),
                            if (isOwner)
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          StaffListScreen(shop: _shop),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.people),
                                label: const Text('Manage Staff'),
                              ),
                            if (isOwner)
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BackupScreen(shop: _shop),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.backup),
                                label: const Text('Backup & Restore'),
                              ),
                            if (isOwner && _shop.isActive)
                              OutlinedButton.icon(
                                onPressed: _deleteShop,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Delete Shop'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _DeleteShopPasswordDialog extends StatefulWidget {
  final String shopName;

  const _DeleteShopPasswordDialog({required this.shopName});

  @override
  State<_DeleteShopPasswordDialog> createState() =>
      _DeleteShopPasswordDialogState();
}

class _DeleteShopPasswordDialogState extends State<_DeleteShopPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Shop'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to deactivate "${widget.shopName}". '
                'Shop data is kept but the shop will be hidden from your list.',
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your account password to confirm you are the owner:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Password is required' : null,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _submit,
          child: const Text('Delete Shop'),
        ),
      ],
    );
  }
}
