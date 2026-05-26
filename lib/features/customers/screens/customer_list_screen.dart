import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../../../core/models/shop_model.dart';
import 'customer_detail_screen.dart';
import 'add_customer_screen.dart'; // we'll create next
import '../../../core/utils/currency_formatter.dart';

class CustomerListScreen extends StatefulWidget {
  final ShopModel shop;
  const CustomerListScreen({super.key, required this.shop});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<CustomerProvider>(context, listen: false)
        .loadCustomers(widget.shop.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CustomerProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: provider.isLoading && provider.customers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.customers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.customers.length,
                  itemBuilder: (_, i) {
                    final customer = provider.customers[i];
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
                          onTap: () => _openCustomerDetail(customer.id),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.person_outline,
                                    size: 32,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.name,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        customer.phone,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Text(
                                            'Balance: ',
                                            style: TextStyle(color: Colors.grey, fontSize: 13),
                                          ),
                                          Text(
                                            CurrencyFormatter.format(customer.currentBalance, widget.shop.currency ?? "TZS"),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: customer.currentBalance > 0 ? Colors.red : Colors.green,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
        label: const Text('New Customer'),
        onPressed: _openAddCustomer,
      ),
    );
  }

  Future<void> _openCustomerDetail(String customerId) async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(
          shop: widget.shop,
          customerId: customerId,
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

  Future<void> _openAddCustomer() async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => AddCustomerScreen(shop: widget.shop),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No customers yet'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _openAddCustomer,
            child: const Text('Add Customer'),
          ),
        ],
      ),
    );
  }
}