import 'package:dukabase/core/utils/connectivity_helper.dart';
import 'package:dukabase/features/auth/providers/auth_provider.dart';
import 'package:dukabase/features/invitations/screens/owner_invitations_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/shop_model.dart';
import '../shops/providers/shop_provider.dart';
import '../staff/screens/staff_list_screen.dart';
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
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _exitIfShopInactive(),
      );
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
            content: Text(verifyResult.error ?? 'Password verification failed'),
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
      body: Container(
        color: Colors.grey[50],
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Information Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.storefront_outlined,
                              color: Colors.deepPurple,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
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
                                const SizedBox(height: 4),
                                Text(
                                  'Details & settings',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Status chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _shop.isActive
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _shop.isActive
                                    ? Colors.green.shade200
                                    : Colors.orange.shade200,
                              ),
                            ),
                            child: Text(
                              _shop.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _shop.isActive
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                      _infoRow(Icons.business_outlined, 'Name', _shop.name),
                      if (_shop.address != null)
                        _infoRow(
                          Icons.location_on_outlined,
                          'Address',
                          _shop.address!,
                        ),
                      if (_shop.phone != null)
                        _infoRow(Icons.phone_outlined, 'Phone', _shop.phone!),
                      _infoRow(Icons.attach_money, 'Currency', _shop.currency),
                      _infoRow(Icons.person_outline, 'Owner ID', _shop.ownerId),
                      _infoRow(
                        Icons.calendar_today_outlined,
                        'Created',
                        DateFormat('dd MMM yyyy').format(_shop.createdAt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Quick Actions Card (only for owner)
                if (isOwner)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.bolt_outlined,
                                color: Colors.deepPurple,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Quick Actions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 28),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _actionButton(
                              onPressed: _editShop,
                              icon: Icons.edit_outlined,
                              label: 'Edit Details',
                              color: Colors.deepPurple,
                            ),
                            _actionButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        OwnerInvitationsScreen(shop: _shop),
                                  ),
                                );
                              },
                              icon: Icons.mail_outline,
                              label: 'Invitations',
                              color: Colors.blue,
                            ),
                            _actionButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        StaffListScreen(shop: _shop),
                                  ),
                                );
                              },
                              icon: Icons.people_outline,
                              label: 'Manage Staff',
                              color: Colors.teal,
                            ),
                            _actionButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BackupScreen(shop: _shop),
                                  ),
                                );
                              },
                              icon: Icons.backup_outlined,
                              label: 'Backup & Restore',
                              color: Colors.orange,
                            ),
                            if (_shop.isActive)
                              _actionButton(
                                onPressed: _deleteShop,
                                icon: Icons.delete_outline,
                                label: 'Delete Shop',
                                color: Colors.red,
                                outlined: true,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Icon(icon, size: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _actionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool outlined = false,
  }) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: 0,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
          const SizedBox(width: 8),
          const Text('Delete Shop'),
        ],
      ),
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
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
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
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
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
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _submit,
          child: const Text('Delete Shop'),
        ),
      ],
    );
  }
}
