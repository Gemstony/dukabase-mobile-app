import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/payment_method_model.dart';
import '../providers/payment_method_provider.dart';
import '../../../core/models/shop_model.dart';
import 'add_payment_method_screen.dart';

class PaymentMethodListScreen extends StatefulWidget {
  final ShopModel shop;
  const PaymentMethodListScreen({super.key, required this.shop});

  @override
  State<PaymentMethodListScreen> createState() => _PaymentMethodListScreenState();
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
      appBar: AppBar(title: Text('Payment Methods - ${widget.shop.name}')),
      body: provider.isLoading && provider.methods.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.methods.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: provider.methods.length,
                  itemBuilder: (_, i) {
                    final method = provider.methods[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Icon(_getIconForType(method.type)),
                        title: Text(method.name),
                        subtitle: Text('Balance: ${method.currentBalance.toStringAsFixed(2)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(method),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddPaymentMethodScreen(shop: widget.shop),
            ),
          );
        },
      ),
    );
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

  void _confirmDelete(PaymentMethodModel method) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text('Are you sure you want to delete ${method.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      final provider = Provider.of<PaymentMethodProvider>(context, listen: false);
      final success = await provider.deletePaymentMethod(widget.shop.id, method.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment method deleted'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed'), backgroundColor: Colors.red),
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
          const Icon(Icons.payment, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No payment methods yet'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddPaymentMethodScreen(shop: widget.shop),
                ),
              );
            },
            child: const Text('Add Payment Method'),
          ),
        ],
      ),
    );
  }
}