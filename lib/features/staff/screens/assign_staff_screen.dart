import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/models/shop_member_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/staff_provider.dart';

class AssignStaffScreen extends StatefulWidget {
  final ShopModel shop;
  const AssignStaffScreen({super.key, required this.shop});

  @override
  State<AssignStaffScreen> createState() => _AssignStaffScreenState();
}

class _AssignStaffScreenState extends State<AssignStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  MemberRole _selectedRole = MemberRole.staff;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final provider = Provider.of<StaffProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await provider.inviteStaff(
      shopId: widget.shop.id,
      email: _emailController.text.trim(),
      invitedByUserId: authProvider.currentUser!.id,
      role: _selectedRole,
    );
    setState(() => _isLoading = false);
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff invited successfully'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Invitation failed'), backgroundColor: Colors.red),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Staff')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address *'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!v.contains('@') || !v.contains('.')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MemberRole>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role *'),
                items: const [
                  DropdownMenuItem(value: MemberRole.staff, child: Text('Staff')),
                  DropdownMenuItem(value: MemberRole.owner, child: Text('Owner')),
                ],
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _invite,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Send Invitation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}