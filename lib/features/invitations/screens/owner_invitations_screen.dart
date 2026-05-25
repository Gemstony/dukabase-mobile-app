import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../staff/providers/staff_provider.dart';
import '../../../core/models/shop_model.dart';

class OwnerInvitationsScreen extends StatefulWidget {
  final ShopModel shop;
  const OwnerInvitationsScreen({super.key, required this.shop});

  @override
  State<OwnerInvitationsScreen> createState() => _OwnerInvitationsScreenState();
}

class _OwnerInvitationsScreenState extends State<OwnerInvitationsScreen> {
  @override
  void initState() {
    super.initState();
    // Load invitations for this shop
    Provider.of<StaffProvider>(context, listen: false)
        .loadShopInvitations(widget.shop.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StaffProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Invitations - ${widget.shop.name}')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.shopInvitations.isEmpty
              ? const Center(child: Text('No invitations sent from this shop'))
              : ListView.builder(
                  itemCount: provider.shopInvitations.length,
                  itemBuilder: (_, i) {
                    final inv = provider.shopInvitations[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text('To: ${inv.inviteeEmail}'),
                        subtitle: Text('Role: ${inv.role.name.toUpperCase()} • Status: ${inv.status.toUpperCase()} • Sent: ${inv.createdAt.toLocal().toString().split(' ')[0]}'),
                        trailing: inv.status == 'pending'
                            ? const Chip(label: Text('Pending'), backgroundColor: Colors.orange)
                            : inv.status == 'accepted'
                                ? const Chip(label: Text('Accepted'), backgroundColor: Colors.green)
                                : const Chip(label: Text('Declined'), backgroundColor: Colors.red),
                      ),
                    );
                  },
                ),
    );
  }
}