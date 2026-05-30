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
        const SnackBar(
          content: Text('Staff invited successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Invitation failed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Staff'),
        centerTitle: false,
      ),
      body: Container(
        color: Colors.grey[50],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Header card
                  Container(
                    padding: const EdgeInsets.all(20),
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
                                Icons.person_add_alt_1_outlined,
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
                                    'Invite Staff Member',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Send an invitation to join ${widget.shop.name}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 28),
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Address *',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (!v.contains('@') || !v.contains('.'))
                              return 'Invalid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Role dropdown
                        DropdownButtonFormField<MemberRole>(
                          initialValue: _selectedRole,
                          decoration: InputDecoration(
                            labelText: 'Role *',
                            prefixIcon: const Icon(Icons.verified_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: MemberRole.staff,
                              child: Text('Staff'),
                            ),
                            DropdownMenuItem(
                              value: MemberRole.owner,
                              child: Text('Owner'),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedRole = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _invite,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_outlined, size: 20),
                      label: Text(_isLoading ? 'Sending...' : 'Send Invitation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}