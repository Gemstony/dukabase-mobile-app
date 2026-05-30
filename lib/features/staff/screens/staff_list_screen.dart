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
    return role.toString().split('.').last.toUpperCase();
  }

  Color _roleColor(MemberRole role) {
    return role == MemberRole.owner
        ? Colors.amber.shade700
        : Colors.blue.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StaffProvider>(context);
    final currentUser = Provider.of<AuthProvider>(context).currentUser;
    final isOwner = widget.shop.ownerId == currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text('Staff • ${widget.shop.name}'),
        centerTitle: false,
      ),
      body: Container(
        color: Colors.grey[50],
        child: provider.isLoading && provider.members.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : provider.members.isEmpty
            ? _buildEmptyState(context)
            : RefreshIndicator(
                // FIX: Wrap the void loadMembers call in a Future to satisfy Future<void> return type
                onRefresh: () =>
                    Future(() => provider.loadMembers(widget.shop.id)),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: provider.members.length,
                  itemBuilder: (_, i) {
                    final member = provider.members[i];
                    final isCurrentUser = member.user.id == currentUser?.id;
                    final roleName = _roleName(member.role);
                    final roleColor = _roleColor(member.role);

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.deepPurple.shade50,
                          child: Text(
                            member.user.name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                        title: Text(
                          member.user.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              member.user.email,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: roleColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    roleName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: roleColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 12,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Joined ${member.joinedAt.toLocal().toString().split(' ')[0]}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text('Remove Staff'),
                                  content: Text(
                                    'Remove ${member.user.name} from this shop?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Remove'),
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
                                      behavior: SnackBarBehavior.floating,
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
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text('Change Role'),
                                  content: Text(
                                    'Change ${member.user.name} role to ${_roleName(newRole)}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
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
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit Details'),
                                ],
                              ),
                            ),
                            if (isOwner && !isCurrentUser)
                              const PopupMenuItem(
                                value: 'changeRole',
                                child: Row(
                                  children: [
                                    Icon(Icons.swap_horiz, size: 18),
                                    SizedBox(width: 8),
                                    Text('Change Role'),
                                  ],
                                ),
                              ),
                            if (isOwner && !isCurrentUser)
                              const PopupMenuItem(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person_remove_outlined,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Remove',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AssignStaffScreen(shop: widget.shop),
                  ),
                ).then((_) => provider.loadMembers(widget.shop.id));
              },
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Invite Staff'),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
              Icons.people_outline,
              size: 80,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Staff Members',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite your first staff member to join ${widget.shop.name}',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
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
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Invite Staff'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
