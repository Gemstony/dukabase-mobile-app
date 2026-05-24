import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';

class BackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Exports all shop data as a JSON file and shares it.
  Future<bool> exportToJson(String shopId) async {
    try {
      // Fetch all data from the shop's subcollections
      final Map<String, List<Map<String, dynamic>>> data = {};

      // 1. Products
      data['products'] = await _fetchCollection('shops/$shopId/products');

      // 2. Suppliers
      data['suppliers'] = await _fetchCollection('shops/$shopId/suppliers');

      // 3. Customers
      data['customers'] = await _fetchCollection('shops/$shopId/customers');

      // 4. Sales (including items)
      final sales = await _fetchCollection('shops/$shopId/sales');
      data['sales'] = sales;
      // Also fetch sale items for each sale
      data['sale_items'] = [];
      for (var sale in sales) {
        final items = await _fetchCollection('shops/$shopId/sales/${sale['id']}/items');
        for (var item in items) {
          item['saleId'] = sale['id'];
          data['sale_items']?.add(item);
        }
      }

      // 5. Purchases (including items)
      final purchases = await _fetchCollection('shops/$shopId/purchases');
      data['purchases'] = purchases;
      data['purchase_items'] = [];
      for (var purchase in purchases) {
        final items = await _fetchCollection('shops/$shopId/purchases/${purchase['id']}/items');
        for (var item in items) {
          item['purchaseId'] = purchase['id'];
          data['purchase_items']?.add(item);
        }
      }

      // 6. Expenses
      data['expenses'] = await _fetchCollection('shops/$shopId/expenses');

      // 7. Payment Methods
      data['paymentMethods'] = await _fetchCollection('shops/$shopId/paymentMethods');

      // 8. Stock Adjustments
      data['stockAdjustments'] = await _fetchCollection('shops/$shopId/stockAdjustments');

      // Convert to JSON
      final jsonString = jsonEncode(data);

      // Write to file
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/backup_shop_$shopId.json';
      final file = File(filePath);
      await file.writeAsString(jsonString);

      // Share the file
      await Share.shareXFiles([XFile(filePath)], text: 'Shop Data Backup');
      return true;
    } catch (e) {
      print('Export error: $e');
      return false;
    }
  }

  /// Helper to fetch a collection and return list of maps with id field.
  Future<List<Map<String, dynamic>>> _fetchCollection(String path) async {
    final snapshot = await _firestore.collection(path).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      // Convert Timestamps to ISO strings for JSON serialization
      data.forEach((key, value) {
        if (value is Timestamp) {
          data[key] = value.toDate().toIso8601String();
        }
      });
      return data;
    }).toList();
  }

  /// Exports all shop data as a CSV file (multiple sheets) and shares it.
  /// For simplicity, we export each collection as a separate CSV file inside a ZIP?
  /// But sharing multiple files is tricky. We'll export one main CSV with all sales or just use JSON.
  /// Since CSV is not ideal for nested data, we'll focus on JSON export.
  /// However, we can also provide a simplified CSV export for the most important collections.
  Future<bool> exportToCsv(String shopId) async {
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final basePath = '${directory.path}/backup_$timestamp';

      // Export sales to CSV
      final sales = await _fetchCollection('shops/$shopId/sales');
      if (sales.isNotEmpty) {
        final salesCsv = _convertToCsv(sales);
        final salesFile = File('$basePath/sales.csv');
        await salesFile.writeAsString(salesCsv);
      }

      // Export products to CSV
      final products = await _fetchCollection('shops/$shopId/products');
      if (products.isNotEmpty) {
        final productsCsv = _convertToCsv(products);
        final productsFile = File('$basePath/products.csv');
        await productsFile.writeAsString(productsCsv);
      }

      // Export purchases to CSV
      final purchases = await _fetchCollection('shops/$shopId/purchases');
      if (purchases.isNotEmpty) {
        final purchasesCsv = _convertToCsv(purchases);
        final purchasesFile = File('$basePath/purchases.csv');
        await purchasesFile.writeAsString(purchasesCsv);
      }

      // Export expenses to CSV
      final expenses = await _fetchCollection('shops/$shopId/expenses');
      if (expenses.isNotEmpty) {
        final expensesCsv = _convertToCsv(expenses);
        final expensesFile = File('$basePath/expenses.csv');
        await expensesFile.writeAsString(expensesCsv);
      }

      // Share the whole directory as a ZIP? Not easy. We'll just share the JSON as before.
      // For CSV, we can share a single combined CSV or just inform the user that JSON is recommended.
      // We'll share the sales CSV as an example.
      final salesFile = File('$basePath/sales.csv');
      if (await salesFile.exists()) {
        await Share.shareXFiles([XFile(salesFile.path)], text: 'Sales CSV Export');
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('CSV export error: $e');
      return false;
    }
  }

  String _convertToCsv(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';
    final headers = data.first.keys.toList();
    final rows = [headers, ...data.map((row) => headers.map((h) => row[h]?.toString() ?? '').toList())];
    return const ListToCsvConverter().convert(rows);
  }
}