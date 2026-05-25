import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/models/shop_member_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/staff_provider.dart';
import 'assign_staff_screen.dart';
import 'edit_staff_screen.dart';

class StaffListScreen extends StatefulWidget {
  final ShopModel shop;
  const StaffListScreen({super.key, required this.shop});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<StaffProvider>(
      context,
      listen: false,
    ).loadMembers(widget.shop.id);
  }

  String _roleName(MemberRole role) {
    return role.toString().split('.').last;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StaffProvider>(context);
    final currentUser = Provider.of<AuthProvider>(context).currentUser;
    final isOwner = widget.shop.ownerId == currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: Text('Staff - ${widget.shop.name}')),
      body: provider.isLoading && provider.members.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.members.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: provider.members.length,
              itemBuilder: (_, i) {
                final member = provider.members[i];
                final isCurrentUser = member.user.id == currentUser?.id;
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(member.user.name[0].toUpperCase()),
                    ),
                    title: Text(member.user.name),
                    subtitle: Text(
                      '${member.user.email} • Role: ${_roleName(member.role).toUpperCase()} • Joined: ${member.joinedAt.toLocal().toString().split(' ')[0]}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditStaffScreen(
                                shopId: widget.shop.id,
                                userId: member.user.id,
                                currentName: member.user.name,
                                currentPhone: member.user.phone,
                              ),
                            ),
                          );
                          provider.loadMembers(widget.shop.id);
                        } else if (value == 'remove' &&
                            isOwner &&
                            !isCurrentUser) {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Remove Staff'),
                              content: Text(
                                'Remove ${member.user.name} from this shop?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'Remove',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final success = await provider.removeStaff(
                              widget.shop.id,
                              member.user.id,
                            );
                            if (success) {
                              provider.loadMembers(widget.shop.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Staff removed'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        } else if (value == 'changeRole' &&
                            isOwner &&
                            !isCurrentUser) {
                          final newRole = member.role == MemberRole.owner
                              ? MemberRole.staff
                              : MemberRole.owner;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Change Role'),
                              content: Text(
                                'Change ${member.user.name} role to ${_roleName(newRole).toUpperCase()}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Confirm'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final success = await provider.updateMemberRole(
                              widget.shop.id,
                              member.user.id,
                              newRole,
                            );
                            if (success) {
                              provider.loadMembers(widget.shop.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Staff role updated'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        }
                      },
                      itemBuilder: (ctx) => [
                        if (isOwner && !isCurrentUser)
                          const PopupMenuItem(
                            value: 'changeRole',
                            child: Text('Change Role'),
                          ),
                        if (isOwner && !isCurrentUser)
                          const PopupMenuItem(
                            value: 'remove',
                            child: Text(
                              'Remove',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit Details'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: isOwner
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AssignStaffScreen(shop: widget.shop),
                  ),
                ).then((_) => provider.loadMembers(widget.shop.id));
              },
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No staff members yet'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AssignStaffScreen(shop: widget.shop),
                ),
              ).then(
                (_) => Provider.of<StaffProvider>(
                  context,
                  listen: false,
                ).loadMembers(widget.shop.id),
              );
            },
            child: const Text('Invite Staff'),
          ),
        ],
      ),
    );
  }
}
