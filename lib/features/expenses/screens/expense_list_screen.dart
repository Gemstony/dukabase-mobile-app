import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/models/expense_model.dart';
import 'add_expense_screen.dart';
import '../../../core/utils/currency_formatter.dart';

class ExpenseListScreen extends StatefulWidget {
  final ShopModel shop;
  const ExpenseListScreen({super.key, required this.shop});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ExpenseProvider>(
        context,
        listen: false,
      ).loadExpenses(widget.shop.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Expenses',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: provider.isLoading && provider.expenses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.expenses.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.expenses.length,
              itemBuilder: (context, index) {
                final expense = provider.expenses[index];
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
                      onTap: () => _showExpenseDetailDialog(context, expense),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.receipt,
                                size: 32,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expense.description,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Category: ${expense.category}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          CurrencyFormatter.format(
                                            expense.amount,
                                            widget.shop.currency ?? "TZS",
                                          ),
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        expense.expenseDate
                                            .toLocal()
                                            .toString()
                                            .split(' ')[0],
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
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
        label: const Text('Add Expense'),
        onPressed: () => _openAddExpense(context),
      ),
    );
  }

  Future<void> _openAddExpense(BuildContext context) async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => AddExpenseScreen(shop: widget.shop)),
    );
    if (message != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showExpenseDetailDialog(
      BuildContext context, ExpenseModel expense) async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final paymentMethodName =
        provider.paymentMethodNames[expense.paymentMethodId] ??
            expense.paymentMethodId;
    final creatorName =
        provider.creatorNames[expense.createdBy] ?? expense.createdBy;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Expense Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow(Icons.description_outlined, 'Description',
                  expense.description),
              const SizedBox(height: 10),
              _detailRow(Icons.monetization_on_outlined, 'Amount',
                  CurrencyFormatter.format(
                      expense.amount, widget.shop.currency ?? 'TZS')),
              const SizedBox(height: 10),
              _detailRow(Icons.category_outlined, 'Category', expense.category),
              const SizedBox(height: 10),
              _detailRow(Icons.payment_outlined, 'Payment Method',
                  paymentMethodName),
              if (expense.referenceNumber != null &&
                  expense.referenceNumber!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _detailRow(Icons.tag_outlined, 'Reference',
                    expense.referenceNumber!),
              ],
              if (expense.note != null && expense.note!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _detailRow(Icons.notes_outlined, 'Note', expense.note!),
              ],
              const Divider(height: 24),
              _detailRow(Icons.person_outline, 'Recorded By', creatorName),
              const SizedBox(height: 10),
              _detailRow(Icons.calendar_today_outlined, 'Date',
                  DateFormat('dd MMM yyyy').format(expense.expenseDate)),
              const SizedBox(height: 10),
              _detailRow(Icons.access_time_outlined, 'Time',
                  DateFormat('hh:mm a').format(expense.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Icon(icon, size: 18, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No expenses recorded yet'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _openAddExpense(context),
            child: const Text('Record First Expense'),
          ),
        ],
      ),
    );
  }
}
