import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supplier_provider.dart';
import '../../../core/models/shop_model.dart';
import 'add_supplier_screen.dart';
import 'supplier_details_screen.dart';
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
      appBar: AppBar(
        title: const Text('Suppliers', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: provider.isLoading && provider.suppliers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.suppliers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = provider.suppliers[index];
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SupplierDetailsScreen(shop: widget.shop, supplier: supplier),
                              ),
                            );
                          },
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
                                    Icons.local_shipping_outlined,
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
                                        supplier.name,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        supplier.phone,
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
                                            CurrencyFormatter.format(supplier.currentBalance, widget.shop.currency ?? "TZS"),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: supplier.currentBalance > 0 ? Colors.red : Colors.green,
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
        label: const Text('New Supplier'),
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