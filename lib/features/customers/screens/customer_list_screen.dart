import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../../../core/models/shop_model.dart';
import 'customer_detail_screen.dart';
import 'add_customer_screen.dart'; // we'll create next

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
      appBar: AppBar(title: Text('Customers - ${widget.shop.name}')),
      body: provider.isLoading && provider.customers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.customers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: provider.customers.length,
                  itemBuilder: (_, i) {
                    final customer = provider.customers[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(customer.name),
                        subtitle: Text('${customer.phone} | Balance: ${customer.currentBalance}'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerDetailScreen(
                                shop: widget.shop,
                                customerId: customer.id,
                              ),
                            ),
                          );
                        },
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
              builder: (_) => AddCustomerScreen(shop: widget.shop),
            ),
          );
        },
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddCustomerScreen(shop: widget.shop),
                ),
              );
            },
            child: const Text('Add Customer'),
          ),
        ],
      ),
    );
  }
}