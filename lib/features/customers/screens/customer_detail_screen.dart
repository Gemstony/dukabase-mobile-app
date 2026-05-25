import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:intl/intl.dart';

import '../../payments/providers/payment_provider.dart';
import '../providers/customer_provider.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/sale_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/models/customer_model.dart';
import '../../../core/models/sale_model.dart';
import '../../../core/models/payment_model.dart';
import '../../../core/utils/currency_formatter.dart';

class CustomerDetailScreen extends StatefulWidget {
  final ShopModel shop;
  final String customerId;

  const CustomerDetailScreen({
    super.key,
    required this.shop,
    required this.customerId,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  late final CustomerService _customerService;
  late final SaleService _saleService;
  late final PaymentService _paymentService;

  CustomerModel? _customer;
  List<SaleModel> _sales = [];
  List<PaymentModel> _payments = [];
  bool _isLoading = true;

  StreamSubscription<List<SaleModel>>? _salesSub;
  StreamSubscription<List<PaymentModel>>? _paymentsSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _customerService = CustomerService();
    _saleService = SaleService();
    _paymentService = PaymentService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final customer = await _customerService.getCustomer(
      widget.shop.id,
      widget.customerId,
    );
    await _salesSub?.cancel();
    _salesSub = _saleService
        .getSalesForCustomer(widget.shop.id, widget.customerId)
        .listen((sales) => setState(() => _sales = sales));

    await _paymentsSub?.cancel();
    _paymentsSub = _paymentService
        .getCustomerPayments(widget.shop.id, widget.customerId)
        .listen((payments) => setState(() => _payments = payments));

    setState(() {
      _customer = customer;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _salesSub?.cancel();
    _paymentsSub?.cancel();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _tabController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer')),
        body: const Center(child: Text('Customer not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_customer!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Customer',
            onPressed: () => _showEditCustomerModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Customer',
            onPressed: () => _confirmDelete(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController!,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: const Color.fromARGB(255, 222, 226, 241),
          unselectedLabelColor: const Color.fromARGB(255, 222, 226, 241),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Sales'),
            Tab(text: 'Payments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController!,
        children: [
          _buildOverviewTab(),
          _buildSalesTab(),
          _buildPaymentsTab(),
        ],
      ),
    );
  }

  // ─── OVERVIEW TAB ──────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 24),
          const Text('Contact Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildContactInfo(),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.payment),
            label: const Text('Record Payment'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _recordPayment,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final hasDebt = _customer!.currentBalance > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
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
                'Outstanding Balance',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasDebt ? Colors.redAccent : Colors.greenAccent.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasDebt ? 'DEBT PENDING' : 'SETTLED',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            CurrencyFormatter.format(_customer!.currentBalance, widget.shop.currency ?? "TZS"),
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Customer Since',
                  DateFormat('MMM d, yyyy').format(_customer!.createdAt),
                  Icons.calendar_today_outlined,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _buildMiniStat(
                  'Total Sales',
                  '${_sales.length} orders',
                  Icons.shopping_cart_outlined,
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
            Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
          BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.phone_outlined, 'Phone', _customer!.phone),
          const Divider(height: 24),
          _buildInfoRow(Icons.email_outlined, 'Email', _customer!.email ?? 'Not provided'),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.account_balance_wallet_outlined,
            'Opening Balance',
            CurrencyFormatter.format(_customer!.openingBalance, widget.shop.currency ?? "TZS"),
          ),
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

  // ─── SALES TAB ─────────────────────────────────────────────────────────────

  Widget _buildSalesTab() {
    if (_sales.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: _buildEmptyContainer('No sales recorded for this customer yet.', Icons.receipt_long_outlined),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sales.length,
      itemBuilder: (_, i) {
        final sale = _sales[i];
        final isCompleted = sale.status == 'completed';
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
                backgroundColor: isCompleted
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
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
                      'Sale #${sale.id.length >= 6 ? sale.id.substring(0, 6).toUpperCase() : sale.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy - HH:mm').format(sale.createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${sale.status.toUpperCase()}',
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
                    CurrencyFormatter.format(sale.totalAmount, widget.shop.currency ?? "TZS"),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Paid: ${CurrencyFormatter.format(sale.paidAmount, widget.shop.currency ?? "TZS")}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── PAYMENTS TAB ──────────────────────────────────────────────────────────

  Widget _buildPaymentsTab() {
    if (_payments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: _buildEmptyContainer('No payments recorded for this customer yet.', Icons.payment_outlined),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      itemBuilder: (_, i) {
        final payment = _payments[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.1),
                child: const Icon(Icons.receipt, color: Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.note.isNotEmpty ? payment.note : 'Payment Received',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy - HH:mm').format(payment.createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(payment.amount, widget.shop.currency ?? "TZS"),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  Widget _buildEmptyContainer(String message, IconData icon) {
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
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  // ─── RECORD PAYMENT ────────────────────────────────────────────────────────

  Future<void> _recordPayment() async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Record Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save Payment'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );

    if (result == true) {
      final amount = double.tryParse(amountController.text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid amount'), backgroundColor: Colors.red),
        );
        return;
      }
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      final success = await paymentProvider.recordPayment(
        shopId: widget.shop.id,
        customerId: widget.customerId,
        amount: amount,
        paymentMethodId: 'cash',
        note: noteController.text,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded'), backgroundColor: Colors.green),
        );
        final updated = await _customerService.getCustomer(widget.shop.id, widget.customerId);
        setState(() => _customer = updated);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(paymentProvider.error ?? 'Failed'), backgroundColor: Colors.red),
        );
        paymentProvider.clearError();
      }
    }
  }

  // ─── EDIT MODAL ────────────────────────────────────────────────────────────

  void _showEditCustomerModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: _customer!.name);
    final phoneController = TextEditingController(text: _customer!.phone);
    final emailController = TextEditingController(text: _customer!.email ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Edit Customer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Customer Name'),
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
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(ctx);

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (c) => const Center(child: CircularProgressIndicator()),
                        );

                        // ignore: use_build_context_synchronously
                        final provider = Provider.of<CustomerProvider>(context, listen: false);
                        final success = await provider.updateCustomer(
                          shopId: widget.shop.id,
                          customerId: _customer!.id,
                          name: nameController.text.trim(),
                          phone: phoneController.text.trim(),
                          email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                        );

                        // ignore: use_build_context_synchronously
                        Navigator.pop(context);

                        if (success) {
                          setState(() {
                            _customer = CustomerModel(
                              id: _customer!.id,
                              shopId: _customer!.shopId,
                              name: nameController.text.trim(),
                              phone: phoneController.text.trim(),
                              email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                              openingBalance: _customer!.openingBalance,
                              currentBalance: _customer!.currentBalance,
                              createdAt: _customer!.createdAt,
                              updatedAt: DateTime.now(),
                            );
                          });
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Customer updated successfully'), backgroundColor: Colors.green),
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

  // ─── DELETE DIALOG ─────────────────────────────────────────────────────────

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${_customer!.name}? This action cannot be undone.'),
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

              final provider = Provider.of<CustomerProvider>(context, listen: false);
              final success = await provider.deleteCustomer(widget.shop.id, _customer!.id);

              // ignore: use_build_context_synchronously
              Navigator.pop(context);

              if (success) {
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Customer deleted successfully'), backgroundColor: Colors.green),
                );
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
