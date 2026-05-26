import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/shop_model.dart';
import '../../../core/models/supplier_model.dart';
import '../../../core/models/purchase_model.dart';
import '../../../core/services/purchase_service.dart';
import '../providers/supplier_provider.dart';
import '../../../core/utils/currency_formatter.dart';

class SupplierDetailsScreen extends StatefulWidget {
  final ShopModel shop;
  final SupplierModel supplier;

  const SupplierDetailsScreen({
    super.key,
    required this.shop,
    required this.supplier,
  });

  @override
  State<SupplierDetailsScreen> createState() => _SupplierDetailsScreenState();
}

class _SupplierDetailsScreenState extends State<SupplierDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PurchaseService _purchaseService = PurchaseService();
  late SupplierModel _currentSupplier;

  @override
  void initState() {
    super.initState();
    _currentSupplier = widget.supplier;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_currentSupplier.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Supplier',
            onPressed: () => _showEditSupplierModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Supplier',
            onPressed: () => _confirmDelete(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: const Color.fromARGB(255, 222, 226, 241),
          unselectedLabelColor: const Color.fromARGB(255, 222, 226, 241),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Purchase History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPurchaseHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 24),
          const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildContactInfo(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final hasDebt = _currentSupplier.currentBalance > 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Balance',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasDebt ? Colors.redAccent : Colors.greenAccent.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasDebt ? 'PAYMENT DUE' : 'SETTLED',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            CurrencyFormatter.format(_currentSupplier.currentBalance, widget.shop.currency ?? "TZS"),
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Added On',
                  DateFormat('MMM d, yyyy').format(_currentSupplier.createdAt),
                  Icons.calendar_today_outlined,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _buildMiniStat(
                  'Opening Bal',
                  CurrencyFormatter.format(_currentSupplier.openingBalance, widget.shop.currency ?? "TZS"),
                  Icons.account_balance_wallet_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.phone_outlined, 'Phone', _currentSupplier.phone),
          const Divider(height: 24),
          _buildInfoRow(Icons.email_outlined, 'Email', _currentSupplier.email ?? 'Not provided'),
          const Divider(height: 24),
          _buildInfoRow(Icons.location_on_outlined, 'Address', _currentSupplier.address ?? 'Not provided'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseHistoryTab() {
    return StreamBuilder<List<PurchaseModel>>(
      stream: _purchaseService.getPurchasesForSupplier(widget.shop.id, _currentSupplier.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildEmptyContainer('Error: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildEmptyContainer('No purchase history with this supplier.'),
          );
        }

        final purchases = snapshot.data!;
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: purchases.length,
          itemBuilder: (context, index) {
            final purchase = purchases[index];
            final isCompleted = purchase.status == 'completed';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isCompleted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    child: Icon(
                      isCompleted ? Icons.check_circle_outline : Icons.pending_actions,
                      color: isCompleted ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy - HH:mm').format(purchase.createdAt),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: ${purchase.status.toUpperCase()}',
                          style: TextStyle(
                            color: isCompleted ? Colors.green : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(purchase.totalAmount, widget.shop.currency ?? "TZS"),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Paid: ${CurrencyFormatter.format(purchase.paidAmount, widget.shop.currency ?? "TZS")}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyContainer(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_toggle_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _showEditSupplierModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: _currentSupplier.name);
    final phoneController = TextEditingController(text: _currentSupplier.phone);
    final emailController = TextEditingController(text: _currentSupplier.email ?? '');
    final addressController = TextEditingController(text: _currentSupplier.address ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Edit Supplier', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Supplier Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email Address (Optional)'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address (Optional)'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(ctx);
                        
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (c) => const Center(child: CircularProgressIndicator()),
                        );
                        
                        // ignore: use_build_context_synchronously
                        final provider = Provider.of<SupplierProvider>(context, listen: false);
                        
                        final result = await provider.updateSupplier(
                          shopId: widget.shop.id,
                          supplierId: _currentSupplier.id,
                          name: nameController.text.trim(),
                          phone: phoneController.text.trim(),
                          email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                          address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                        );
                        
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context); // close loading
                        
                        if (result.success) {
                          setState(() {
                            // Rebuild UI with local modifications
                            _currentSupplier = SupplierModel(
                              id: _currentSupplier.id,
                              shopId: _currentSupplier.shopId,
                              name: nameController.text.trim(),
                              phone: phoneController.text.trim(),
                              email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                              address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                              openingBalance: _currentSupplier.openingBalance,
                              currentBalance: _currentSupplier.currentBalance,
                              createdAt: _currentSupplier.createdAt,
                              updatedAt: DateTime.now(),
                            );
                          });
                          final message = result.pendingSync
                              ? 'Supplier update saved offline — will sync when you\'re back online'
                              : 'Supplier updated successfully';
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message), backgroundColor: Colors.green),
                          );
                        } else {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(provider.error ?? 'Update failed'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Are you sure you want to delete ${_currentSupplier.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) => const Center(child: CircularProgressIndicator()),
              );
              
              final provider = Provider.of<SupplierProvider>(context, listen: false);
              final result = await provider.deleteSupplier(
                widget.shop.id,
                _currentSupplier.id,
              );
              
              // ignore: use_build_context_synchronously
              Navigator.pop(context); // Close loading
              
              if (result.success) {
                final message = result.pendingSync
                    ? 'Supplier deletion saved offline — will sync when you\'re back online'
                    : 'Supplier deleted successfully';
                // ignore: use_build_context_synchronously
                Navigator.pop(context, message); // Go back to list screen
              } else {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(provider.error ?? 'Delete failed'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
