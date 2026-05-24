import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../payments/providers/payment_provider.dart';
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

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
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
    // cancel previous subscriptions to avoid duplicated listeners
    await _salesSub?.cancel();
    _salesSub = _saleService
        .getSalesForCustomer(widget.shop.id, widget.customerId)
        .listen((sales) {
          setState(() => _sales = sales);
        });
    await _paymentsSub?.cancel();
    _paymentsSub = _paymentService
        .getCustomerPayments(widget.shop.id, widget.customerId)
        .listen((payments) {
          setState(() => _payments = payments);
        });
    setState(() {
      _customer = customer;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _salesSub?.cancel();
    _paymentsSub?.cancel();
    super.dispose();
  }

  Future<void> _recordPayment() async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == true) {
      final amount = double.tryParse(amountController.text);
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid amount'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final paymentProvider = Provider.of<PaymentProvider>(
        context,
        listen: false,
      );
      final success = await paymentProvider.recordPayment(
        shopId: widget.shop.id,
        customerId: widget.customerId,
        amount: amount,
        paymentMethodId: 'cash', // you can extend this later
        note: noteController.text,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the customer so outstanding balance updates immediately
        final updated = await _customerService.getCustomer(
          widget.shop.id,
          widget.customerId,
        );
        setState(() => _customer = updated);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentProvider.error ?? 'Failed'),
            backgroundColor: Colors.red,
          ),
        );
        paymentProvider.clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer')),
        body: const Center(child: Text('Customer not found')),
      );
    }
    final outstanding = _customer!.currentBalance;
    return Scaffold(
      appBar: AppBar(title: Text(_customer!.name)),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          children: [
            // Customer info card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _customer!.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Phone: ${_customer!.phone}'),
                    if (_customer!.email != null)
                      Text('Email: ${_customer!.email}'),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Outstanding Balance:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          CurrencyFormatter.format(outstanding, widget.shop.currency ?? "TZS"),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: outstanding > 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _recordPayment,
                      icon: const Icon(Icons.payment),
                      label: const Text('Record Payment'),
                    ),
                  ],
                ),
              ),
            ),
            // Sales history
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Sales History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            _sales.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No sales yet'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _sales.length,
                    itemBuilder: (_, i) {
                      final sale = _sales[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          isThreeLine: true,

                          title: Text(
                            'Sale #${sale.id.length >= 6 ? sale.id.substring(0, 6) : sale.id}',
                          ),

                          subtitle: Text(
                            'Date: ${sale.createdAt.toLocal().toString().split(' ')[0]}',
                          ),

                          trailing: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Total: ${CurrencyFormatter.format(sale.totalAmount, widget.shop.currency ?? "TZS")}',
                                ),

                                Text(
                                  'Paid: ${CurrencyFormatter.format(sale.paidAmount, widget.shop.currency ?? "TZS")}',
                                  style: const TextStyle(fontSize: 12),
                                ),

                                if (sale.status == 'pending')
                                  const Text(
                                    'Pending',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            // Payment history
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Payment History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _payments.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No payments recorded yet'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _payments.length,
                    itemBuilder: (_, i) {
                      final payment = _payments[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.receipt),
                          title: Text(
                            '${CurrencyFormatter.format(payment.amount, widget.shop.currency ?? "TZS")} received',
                          ),
                          subtitle: Text(
                            payment.note.isNotEmpty ? payment.note : 'No note',
                          ),
                          trailing: Text(
                            payment.createdAt.toLocal().toString().split(
                              ' ',
                            )[0],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
