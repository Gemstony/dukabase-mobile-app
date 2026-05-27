import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/models/purchase_model.dart';
import 'package:intl/intl.dart';

class PurchasesListScreen extends StatefulWidget {
  final ShopModel shop;
  final String? successMessage;

  const PurchasesListScreen({
    super.key,
    required this.shop,
    this.successMessage,
  });

  @override
  State<PurchasesListScreen> createState() => _PurchasesListScreenState();
}

class _PurchasesListScreenState extends State<PurchasesListScreen> {
  final List<PurchaseModel> _purchases = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;
  double _totalPurchasesLoaded = 0.0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final message = widget.successMessage;
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
    _fetchPurchases();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _fetchPurchases();
      }
    });
  }

  Future<void> _fetchPurchases() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      var query = FirebaseFirestore.instance
          .collection('shops')
          .doc(widget.shop.id)
          .collection('purchases')
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
        final newPurchases = snapshot.docs
            .map((doc) => PurchaseModel.fromMap(doc.id, doc.data()))
            .toList();
        _purchases.addAll(newPurchases);

        // Accumulate total for loaded purchases
        _totalPurchasesLoaded += newPurchases.fold(
          0.0,
          (sum, p) => sum + p.totalAmount,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
      appBar: AppBar(title: const Text('Recent Purchases'), elevation: 0),
      body: _purchases.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _purchases.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No purchases recorded yet.',
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.shop.currency} ${_totalPurchasesLoaded.toStringAsFixed(2)}',
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
                    itemCount: _purchases.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _purchases.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final purchase = _purchases[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: purchase.status == 'completed'
                                ? Colors.green.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                            child: Icon(
                              purchase.status == 'completed'
                                  ? Icons.check_circle
                                  : Icons.pending,
                              color: purchase.status == 'completed'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                          title: Text(
                            '${widget.shop.currency} ${purchase.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Supplier: ${purchase.supplierName}\nDate: ${DateFormat('MMM dd, yyyy - hh:mm a').format(purchase.createdAt.toLocal())}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                          isThreeLine: true,
                          trailing: Text(
                            'Paid: ${purchase.paidAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: purchase.paidAmount >= purchase.totalAmount
                                  ? Colors.green
                                  : Colors.red,
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
