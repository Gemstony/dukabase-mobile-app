import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../../../core/models/shop_model.dart';
import 'add_expense_screen.dart';

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
      Provider.of<ExpenseProvider>(context, listen: false)
          .loadExpenses(widget.shop.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Expenses - ${widget.shop.name}')),
      body: provider.isLoading && provider.expenses.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.expenses.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: provider.expenses.length,
                  itemBuilder: (_, i) {
                    final expense = provider.expenses[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.receipt, color: Colors.red),
                        title: Text(expense.description),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category: ${expense.category}'),
                            Text('Date: ${expense.expenseDate.toLocal().toString().split(' ')[0]}'),
                          ],
                        ),
                        trailing: Text(
                          '-${expense.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 16,
                          ),
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
              builder: (_) => AddExpenseScreen(shop: widget.shop),
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
          const Icon(Icons.receipt_long, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No expenses recorded yet'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddExpenseScreen(shop: widget.shop),
                ),
              );
            },
            child: const Text('Record First Expense'),
          ),
        ],
      ),
    );
  }
}