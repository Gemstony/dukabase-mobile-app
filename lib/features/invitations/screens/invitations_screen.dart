import 'package:dukabase/core/models/invitation_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../staff/providers/staff_provider.dart';

class InvitationsScreen extends StatelessWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StaffProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Invitations')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: provider.getPendingInvitationsWithShop(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading invitations: ${snapshot.error}'));
          }
          final invitations = snapshot.data ?? [];
          if (invitations.isEmpty) {
            return const Center(child: Text('No pending invitations'));
          }
          return ListView.builder(
            itemCount: invitations.length,
            itemBuilder: (_, i) {
              final item = invitations[i];
              final inv = item['invitation'] as InvitationModel;
              final shopName = item['shopName'] as String;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(shopName),
                  subtitle: Text('Role: ${inv.role.name.toUpperCase()} • Sent: ${inv.createdAt.toLocal().toString().split(' ')[0]}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          final success = await provider.acceptInvitation(inv.id);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Accepted'), backgroundColor: Colors.green),
                            );
                            // Optionally refresh or pop
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          final success = await provider.declineInvitation(inv.id);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Declined'), backgroundColor: Colors.orange),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}