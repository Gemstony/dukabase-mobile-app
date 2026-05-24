import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supplier_provider.dart';
import '../../../core/models/shop_model.dart';
import 'add_supplier_screen.dart';
import '../../../core/utils/currency_formatter.dart';

class SupplierListScreen extends StatefulWidget {
  final ShopModel shop;
  const SupplierListScreen({super.key, required this.shop});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<SupplierProvider>(context, listen: false)
        .loadSuppliers(widget.shop.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SupplierProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Suppliers - ${widget.shop.name}')),
      body: provider.isLoading && provider.suppliers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.suppliers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: provider.suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = provider.suppliers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(supplier.name),
                        subtitle: Text('${supplier.phone} | Balance: ${CurrencyFormatter.format(supplier.currentBalance, widget.shop.currency ?? "TZS")}'),
                        trailing: Text(supplier.email ?? ''),
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
              builder: (_) => AddSupplierScreen(shop: widget.shop),
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
          const Text('No suppliers yet'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddSupplierScreen(shop: widget.shop),
                ),
              );
            },
            child: const Text('Add Supplier'),
          ),
        ],
      ),
    );
  }
}