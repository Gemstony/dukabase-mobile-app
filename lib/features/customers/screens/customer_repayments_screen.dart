import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/models/payment_model.dart';
import '../../../core/utils/currency_formatter.dart';

class CustomerRepaymentsScreen extends StatefulWidget {
  final ShopModel shop;
  const CustomerRepaymentsScreen({super.key, required this.shop});

  @override
  State<CustomerRepaymentsScreen> createState() =>
      _CustomerRepaymentsScreenState();
}

class _CustomerRepaymentsScreenState extends State<CustomerRepaymentsScreen> {
  final PaymentService _paymentService = PaymentService();
  List<({PaymentModel payment, String customerName})> _repayments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRepayments();
  }

  Future<void> _loadRepayments() async {
    setState(() => _isLoading = true);
    try {
      final stream = _paymentService.getAllPayments(widget.shop.id);
      stream.listen((paymentsWithNames) {
        if (mounted) {
          setState(() {
            _repayments = paymentsWithNames;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Customer Repayments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRepayments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _repayments.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () async => _loadRepayments(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _repayments.length,
                itemBuilder: (_, index) {
                  final item = _repayments[index];
                  return _buildRepaymentCard(
                    payment: item.payment,
                    customerName: item.customerName,
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No repayments recorded yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customer payments will appear here',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildRepaymentCard({
    required PaymentModel payment,
    required String customerName,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.withOpacity(0.1),
            child: const Icon(Icons.person, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy - HH:mm').format(payment.createdAt),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                if (payment.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    payment.note,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(
              payment.amount,
              widget.shop.currency ?? 'TZS',
            ),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
