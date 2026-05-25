import 'package:dukabase/features/auth/providers/auth_provider.dart';
import 'package:dukabase/features/invitations/screens/owner_invitations_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/models/shop_model.dart';
import '../../core/utils/currency_formatter.dart';
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
  }

  Future<void> _refresh() async {
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    shopProvider.loadUserShops(
      shopProvider.shops.isNotEmpty ? shopProvider.shops.first.ownerId : '',
    );
    // Alternatively, fetch single shop:
    final refreshed = await Provider.of<ShopProvider>(
      context,
      listen: false,
    ).getShopById(_shop.id);
    if (refreshed != null) setState(() => _shop = refreshed);
  }

  Future<void> _editShop() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditShopScreen(shop: _shop)),
    );
    if (updated == true) await _refresh();
  }

  Future<void> _deleteShop() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Shop'),
        content: const Text(
          'Are you sure? This will deactivate the shop (data remains but shop will be hidden). This action can be reversed by an admin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final provider = Provider.of<ShopProvider>(context, listen: false);
    final success = await provider.deleteShop(_shop.id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop deactivated'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // go back to shop list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Delete failed'),
          backgroundColor: Colors.red,
        ),
      );
      provider.clearError();
    }
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
