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
    Provider.of<StaffProvider>(context, listen: false)
        .loadShopInvitations(widget.shop.id);
  }

  String _statusLabel(String status) {
    return status.toUpperCase();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StaffProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Invitations • ${widget.shop.name}'),
        centerTitle: false,
      ),
      body: Container(
        color: Colors.grey[50],
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.shopInvitations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send_outlined,
                            size: 80,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No Invitations Sent',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Invitations you send to staff will appear here.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => provider.loadShopInvitations(widget.shop.id),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: provider.shopInvitations.length,
                      itemBuilder: (_, i) {
                        final inv = provider.shopInvitations[i];
                        final statusLabel = _statusLabel(inv.status);
                        final statusColor = _statusColor(inv.status);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.deepPurple.shade50,
                                      child: Text(
                                        inv.inviteeEmail[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            inv.inviteeEmail,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.verified_user,
                                                  size: 14, color: Colors.grey.shade600),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Role: ${inv.role.name.toUpperCase()}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: statusColor.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined,
                                        size: 14, color: Colors.grey.shade500),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Sent: ${inv.createdAt.toLocal().toString().split(' ')[0]}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}