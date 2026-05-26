import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/shop_model.dart';
import '../../../core/models/payment_method_model.dart';
import '../../../core/models/sale_model.dart';
import '../../../core/models/purchase_model.dart';
import '../../../core/services/payment_method_service.dart';
import '../providers/payment_method_provider.dart';
import '../../../core/utils/currency_formatter.dart';

class PaymentMethodDetailsScreen extends StatefulWidget {
  final ShopModel shop;
  final PaymentMethodModel method;

  const PaymentMethodDetailsScreen({
    super.key,
    required this.shop,
    required this.method,
  });

  @override
  State<PaymentMethodDetailsScreen> createState() =>
      _PaymentMethodDetailsScreenState();
}

class _PaymentMethodDetailsScreenState
    extends State<PaymentMethodDetailsScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final PaymentMethodService _service = PaymentMethodService();
  late PaymentMethodModel _currentMethod;

  @override
  void initState() {
    super.initState();
    _currentMethod = widget.method;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  IconData _getIconForType(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.cash:
        return Icons.money;
      case PaymentMethodType.bank:
        return Icons.account_balance;
      case PaymentMethodType.mobile_money:
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  String _getTypeLabel(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.cash:
        return 'Cash';
      case PaymentMethodType.bank:
        return 'Bank Account';
      case PaymentMethodType.mobile_money:
        return 'Mobile Money';
      default:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_currentMethod.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Payment Method',
            onPressed: () => _showEditModal(context),
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
            Tab(text: 'Purchases'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController!,
        children: [
          _buildOverviewTab(),
          _buildSalesTab(),
          _buildPurchasesTab(),
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
          const Text('Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildDetailsCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final isPositive = _currentMethod.currentBalance >= 0;
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
              Text(
                _getTypeLabel(_currentMethod.type),
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _currentMethod.isActive
                      ? Colors.greenAccent.withOpacity(0.9)
                      : Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _currentMethod.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(_getIconForType(_currentMethod.type),
                  color: Colors.white54, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  CurrencyFormatter.format(
                      _currentMethod.currentBalance,
                      widget.shop.currency ?? "TZS"),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Text('Current Balance',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Initial Balance',
                  CurrencyFormatter.format(
                      _currentMethod.initialBalance,
                      widget.shop.currency ?? "TZS"),
                  Icons.account_balance_wallet_outlined,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _buildMiniStat(
                  'Net Change',
                  CurrencyFormatter.format(
                      _currentMethod.currentBalance -
                          _currentMethod.initialBalance,
                      widget.shop.currency ?? "TZS"),
                  isPositive
                      ? Icons.trending_up
                      : Icons.trending_down,
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
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildInfoRow(
              Icons.label_outline, 'Name', _currentMethod.name),
          const Divider(height: 24),
          _buildInfoRow(
              _getIconForType(_currentMethod.type),
              'Type',
              _getTypeLabel(_currentMethod.type)),
          const Divider(height: 24),
          _buildInfoRow(
              Icons.calendar_today_outlined,
              'Created On',
              DateFormat('MMM d, yyyy').format(_currentMethod.createdAt)),
          const Divider(height: 24),
          _buildInfoRow(
              Icons.update,
              'Last Updated',
              DateFormat('MMM d, yyyy').format(_currentMethod.updatedAt)),
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
          child:
              Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── SALES TAB ─────────────────────────────────────────────────────────────

  Widget _buildSalesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _service.getSalesForMethod(
          widget.shop.id, _currentMethod.id,
          limit: 30),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: _buildEmpty(
                'Error loading sales: ${snapshot.error}',
                Icons.error_outline),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: _buildEmpty(
                'No sales recorded through this payment method.',
                Icons.receipt_long_outlined),
          );
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final sale = SaleModel.fromMap(docs[i].id, data);
            final isCompleted = sale.status == 'completed';
            return _buildTransactionCard(
              icon: isCompleted
                  ? Icons.check_circle_outline
                  : Icons.pending_actions,
              iconColor: isCompleted ? Colors.green : Colors.orange,
              bgColor: isCompleted
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderColor: Colors.green.withOpacity(0.2),
              title:
                  'Sale #${sale.id.length >= 6 ? sale.id.substring(0, 6).toUpperCase() : sale.id}',
              subtitle: DateFormat('MMM d, yyyy - HH:mm')
                  .format(sale.createdAt),
              badge: sale.status.toUpperCase(),
              badgeColor: isCompleted ? Colors.green : Colors.orange,
              amount: CurrencyFormatter.format(
                  sale.totalAmount, widget.shop.currency ?? "TZS"),
              subAmount:
                  'Paid: ${CurrencyFormatter.format(sale.paidAmount, widget.shop.currency ?? "TZS")}',
            );
          },
        );
      },
    );
  }

  // ─── PURCHASES TAB ─────────────────────────────────────────────────────────

  Widget _buildPurchasesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _service.getPurchasesForMethod(
          widget.shop.id, _currentMethod.id,
          limit: 30),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: _buildEmpty(
                'Error loading purchases: ${snapshot.error}',
                Icons.error_outline),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: _buildEmpty(
                'No purchases recorded through this payment method.',
                Icons.shopping_bag_outlined),
          );
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final purchase = PurchaseModel.fromMap(docs[i].id, data);
            final isCompleted = purchase.status == 'completed';
            return _buildTransactionCard(
              icon: isCompleted
                  ? Icons.check_circle_outline
                  : Icons.pending_actions,
              iconColor: isCompleted ? Colors.green : Colors.orange,
              bgColor: isCompleted
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderColor: Colors.orange.withOpacity(0.2),
              title: purchase.supplierName,
              subtitle: DateFormat('MMM d, yyyy - HH:mm')
                  .format(purchase.createdAt),
              badge: purchase.status.toUpperCase(),
              badgeColor: isCompleted ? Colors.green : Colors.orange,
              amount: CurrencyFormatter.format(
                  purchase.totalAmount, widget.shop.currency ?? "TZS"),
              subAmount:
                  'Paid: ${CurrencyFormatter.format(purchase.paidAmount, widget.shop.currency ?? "TZS")}',
            );
          },
        );
      },
    );
  }

  // ─── SHARED WIDGETS ────────────────────────────────────────────────────────

  Widget _buildTransactionCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required String amount,
    required String subAmount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: bgColor,
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 4),
                Text(badge,
                    style: TextStyle(
                        color: badgeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(subAmount,
                  style:
                      TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String message, IconData icon) {
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
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  // ─── EDIT MODAL ────────────────────────────────────────────────────────────

  void _showEditModal(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController =
        TextEditingController(text: _currentMethod.name);
    PaymentMethodType selectedType = _currentMethod.type;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
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
                    const Text('Edit Payment Method',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'Name'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PaymentMethodType>(
                      initialValue: selectedType,
                      decoration:
                          const InputDecoration(labelText: 'Type'),
                      items: PaymentMethodType.values
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(_getTypeLabel(t)),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setModalState(() => selectedType = v);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(ctx);

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (c) => const Center(
                                child: CircularProgressIndicator()),
                          );

                          // ignore: use_build_context_synchronously
                          final provider =
                              Provider.of<PaymentMethodProvider>(
                                  context,
                                  listen: false);
                          final result =
                              await provider.updatePaymentMethod(
                            shopId: widget.shop.id,
                            methodId: _currentMethod.id,
                            name: nameController.text.trim(),
                            type: selectedType,
                          );

                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);

                          if (result.success) {
                            setState(() {
                              _currentMethod = PaymentMethodModel(
                                id: _currentMethod.id,
                                shopId: _currentMethod.shopId,
                                name: nameController.text.trim(),
                                type: selectedType,
                                initialBalance:
                                    _currentMethod.initialBalance,
                                currentBalance:
                                    _currentMethod.currentBalance,
                                isActive: _currentMethod.isActive,
                                createdAt: _currentMethod.createdAt,
                                updatedAt: DateTime.now(),
                              );
                            });
                            final message = result.pendingSync
                                ? 'Update saved offline — will sync when you\'re back online'
                                : 'Payment method updated successfully';
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(message),
                                  backgroundColor: Colors.green),
                            );
                          } else {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      provider.error ?? 'Update failed'),
                                  backgroundColor: Colors.red),
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
        });
      },
    );
  }
}
