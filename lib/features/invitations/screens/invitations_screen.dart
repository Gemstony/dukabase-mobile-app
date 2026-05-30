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
      appBar: AppBar(
        title: const Text('Your Invitations'),
        centerTitle: false,
      ),
      body: Container(
        color: Colors.grey[50],
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: provider.getPendingInvitationsWithShop(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text('Error loading invitations: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.getPendingInvitationsWithShop(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            final invitations = snapshot.data ?? [];
            if (invitations.isEmpty) {
              return Center(
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
                        Icons.mail_outline,
                        size: 80,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Pending Invitations',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When someone invites you to a shop,\nit will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: invitations.length,
              itemBuilder: (_, i) {
                final item = invitations[i];
                final inv = item['invitation'] as InvitationModel;
                final shopName = item['shopName'] as String;
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
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.deepPurple.shade50,
                          child: Text(
                            shopName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shopName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Role: ${inv.role.name.toUpperCase()}',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.schedule, size: 12, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Sent: ${inv.createdAt.toLocal().toString().split(' ')[0]}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _actionButton(
                              icon: Icons.check,
                              color: Colors.green,
                              onPressed: () async {
                                final success = await provider.acceptInvitation(inv.id);
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invitation accepted'),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            _actionButton(
                              icon: Icons.close,
                              color: Colors.red,
                              onPressed: () async {
                                final success = await provider.declineInvitation(inv.id);
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invitation declined'),
                                      backgroundColor: Colors.orange,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}