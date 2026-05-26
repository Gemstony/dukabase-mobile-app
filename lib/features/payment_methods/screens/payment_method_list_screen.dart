import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/payment_method_model.dart';
import '../providers/payment_method_provider.dart';
import '../../../core/models/shop_model.dart';
import 'add_payment_method_screen.dart';
import 'payment_method_details_screen.dart';
import '../../../core/utils/currency_formatter.dart';

class PaymentMethodListScreen extends StatefulWidget {
  final ShopModel shop;
  const PaymentMethodListScreen({super.key, required this.shop});

  @override
  State<PaymentMethodListScreen> createState() =>
      _PaymentMethodListScreenState();
}

class _PaymentMethodListScreenState extends State<PaymentMethodListScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<PaymentMethodProvider>(context, listen: false)
        .loadPaymentMethods(widget.shop.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PaymentMethodProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: provider.isLoading && provider.methods.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.methods.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.methods.length,
                  itemBuilder: (_, i) {
                    final method = provider.methods[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _openMethodDetail(method),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(method.type)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getIconForType(method.type),
                                    size: 30,
                                    color: _getTypeColor(method.type),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            method.name,
                                            style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2),
                                            decoration: BoxDecoration(
                                              color:
                                                  _getTypeColor(method.type)
                                                      .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _getTypeLabel(method.type),
                                              style: TextStyle(
                                                color: _getTypeColor(
                                                    method.type),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Balance: ${CurrencyFormatter.format(method.currentBalance, widget.shop.currency ?? 'TZS')}',
                                        style: TextStyle(
                                          color:
                                              method.currentBalance >= 0
                                                  ? Colors.green[700]
                                                  : Colors.red,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    const Icon(Icons.arrow_forward_ios,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () => _confirmDelete(method),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.delete,
                                            size: 18, color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Method'),
        onPressed: _openAddMethod,
      ),
    );
  }

  Future<void> _openMethodDetail(PaymentMethodModel method) async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodDetailsScreen(
          shop: widget.shop,
          method: method,
        ),
      ),
    );
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _openAddMethod() async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPaymentMethodScreen(shop: widget.shop),
      ),
    );
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

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

  Color _getTypeColor(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.cash:
        return Colors.green;
      case PaymentMethodType.bank:
        return Colors.blue;
      case PaymentMethodType.mobile_money:
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.cash:
        return 'Cash';
      case PaymentMethodType.bank:
        return 'Bank';
      case PaymentMethodType.mobile_money:
        return 'Mobile Money';
      default:
        return 'Other';
    }
  }

  void _confirmDelete(PaymentMethodModel method) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Payment Method'),
        content: Text(
            'Are you sure you want to deactivate "${method.name}"? It will no longer appear in lists.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final provider =
          Provider.of<PaymentMethodProvider>(context, listen: false);
      final result =
          await provider.deletePaymentMethod(widget.shop.id, method.id);
      if (!mounted) return;
      if (result.success) {
        final message = result.pendingSync
            ? 'Deactivation saved offline — will sync when you\'re back online'
            : 'Payment method deactivated';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(provider.error ?? 'Failed'),
              backgroundColor: Colors.red),
        );
        provider.clearError();
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.payment,
                size: 64, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 20),
          const Text('No Payment Methods Yet',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Add a payment method to start tracking',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Payment Method'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _openAddMethod,
          ),
        ],
      ),
    );
  }
}
