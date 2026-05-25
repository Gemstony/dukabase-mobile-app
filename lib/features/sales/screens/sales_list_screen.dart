import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/models/sale_model.dart';
import 'package:intl/intl.dart';

class SalesListScreen extends StatefulWidget {
  final ShopModel shop;
  
  const SalesListScreen({super.key, required this.shop});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  final List<SaleModel> _sales = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;
  double _totalSalesLoaded = 0.0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchSales();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _fetchSales();
      }
    });
  }

  Future<void> _fetchSales() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      var query = FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shop.id)
          .collection('sales')
          .orderBy('createdAt', descending: true)
          .limit(10);

      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.length < 10) {
        _hasMore = false;
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
        final newSales = snapshot.docs.map((doc) => SaleModel.fromMap(doc.id, doc.data())).toList();
        _sales.addAll(newSales);
        
        // Accumulate total for loaded sales
        _totalSalesLoaded += newSales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Sales'),
        elevation: 0,
      ),
      body: _sales.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sales.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No sales recorded yet.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total (Loaded):',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${widget.shop.currency} ${_totalSalesLoaded.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: _sales.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _sales.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final sale = _sales[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: sale.status == 'completed' ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                child: Icon(
                                  sale.status == 'completed' ? Icons.check_circle : Icons.pending,
                                  color: sale.status == 'completed' ? Colors.green : Colors.orange,
                                ),
                              ),
                              title: Text(
                                '${widget.shop.currency} ${sale.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Date: ${DateFormat('MMM dd, yyyy - hh:mm a').format(sale.createdAt.toLocal())}\nStatus: ${sale.status.toUpperCase()}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ),
                              isThreeLine: true,
                              trailing: Text(
                                'Paid: ${sale.paidAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: sale.paidAmount >= sale.totalAmount ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
