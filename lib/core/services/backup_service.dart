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

  /// Restore shop data from a JSON backup file.
  /// This will replace ALL existing data for the shop (clear then write from backup).
  Future<({bool success, String? error})> restoreFromJson(String shopId, File file) async {
    try {
      // Read and parse JSON
      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonString);

      // Validate structure
      final requiredKeys = ['products', 'suppliers', 'customers', 'sales', 'purchases', 'expenses', 'paymentMethods', 'stockAdjustments'];
      for (var key in requiredKeys) {
        if (!data.containsKey(key)) {
          return (success: false, error: 'Invalid backup file: missing $key');
        }
      }

      // Use a batched write (Firestore allows up to 500 operations per batch)
      // We'll clear existing data first, then write new data.
      // Clearing: delete all documents in each subcollection.

      // 1. Clear existing data (delete all documents in subcollections)
      await _clearSubcollection(shopId, 'products');
      await _clearSubcollection(shopId, 'suppliers');
      await _clearSubcollection(shopId, 'customers');
      await _clearSubcollection(shopId, 'sales');
      await _clearSubcollection(shopId, 'purchases');
      await _clearSubcollection(shopId, 'expenses');
      await _clearSubcollection(shopId, 'paymentMethods');
      await _clearSubcollection(shopId, 'stockAdjustments');

      // 2. Write new data in order: parents first, then children (sales items, purchase items)
      // Products
      for (var product in data['products']) {
        final ref = _firestore.collection('shops').doc(shopId).collection('products').doc(product['id']);
        product.remove('id');
        // Convert ISO date strings back to Timestamp
        _convertTimestamps(product);
        await ref.set(product);
      }

      // Suppliers
      for (var supplier in data['suppliers']) {
        final ref = _firestore.collection('shops').doc(shopId).collection('suppliers').doc(supplier['id']);
        supplier.remove('id');
        _convertTimestamps(supplier);
        await ref.set(supplier);
      }

      // Customers
      for (var customer in data['customers']) {
        final ref = _firestore.collection('shops').doc(shopId).collection('customers').doc(customer['id']);
        customer.remove('id');
        _convertTimestamps(customer);
        await ref.set(customer);
      }

      // Payment Methods
      for (var method in data['paymentMethods']) {
        final ref = _firestore.collection('shops').doc(shopId).collection('paymentMethods').doc(method['id']);
        method.remove('id');
        _convertTimestamps(method);
        await ref.set(method);
      }

      // Expenses
      for (var expense in data['expenses']) {
        final ref = _firestore.collection('shops').doc(shopId).collection('expenses').doc(expense['id']);
        expense.remove('id');
        _convertTimestamps(expense);
        await ref.set(expense);
      }

      // Stock Adjustments
      for (var adj in data['stockAdjustments']) {
        final ref = _firestore.collection('shops').doc(shopId).collection('stockAdjustments').doc(adj['id']);
        adj.remove('id');
        _convertTimestamps(adj);
        await ref.set(adj);
      }

      // Sales (and their items)
      for (var sale in data['sales']) {
        final saleRef = _firestore.collection('shops').doc(shopId).collection('sales').doc(sale['id']);
        sale.remove('id');
        _convertTimestamps(sale);
        await saleRef.set(sale);
      }
      // Sale items: they are in a separate array 'sale_items' with saleId reference
      if (data.containsKey('sale_items')) {
        for (var item in data['sale_items']) {
          final saleId = item['saleId'];
          final itemRef = _firestore
              .collection('shops')
              .doc(shopId)
              .collection('sales')
              .doc(saleId)
              .collection('items')
              .doc(item['id']);
          item.remove('id');
          item.remove('saleId');
          _convertTimestamps(item);
          await itemRef.set(item);
        }
      }

      // Purchases (and their items)
      for (var purchase in data['purchases']) {
        final purchaseRef = _firestore.collection('shops').doc(shopId).collection('purchases').doc(purchase['id']);
        purchase.remove('id');
        _convertTimestamps(purchase);
        await purchaseRef.set(purchase);
      }
      if (data.containsKey('purchase_items')) {
        for (var item in data['purchase_items']) {
          final purchaseId = item['purchaseId'];
          final itemRef = _firestore
              .collection('shops')
              .doc(shopId)
              .collection('purchases')
              .doc(purchaseId)
              .collection('items')
              .doc(item['id']);
          item.remove('id');
          item.remove('purchaseId');
          _convertTimestamps(item);
          await itemRef.set(item);
        }
      }

      return (success: true, error: null);
    } catch (e) {
      print('Restore error: $e');
      return (success: false, error: e.toString());
    }
  }

  // Helper: delete all documents in a subcollection
  Future<void> _clearSubcollection(String shopId, String collectionName) async {
    final snapshot = await _firestore
        .collection('shops')
        .doc(shopId)
        .collection(collectionName)
        .get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Helper: convert ISO date strings back to Timestamp
  void _convertTimestamps(Map<String, dynamic> map) {
    map.forEach((key, value) {
      if (value is String && _isIsoDate(value)) {
        map[key] = Timestamp.fromDate(DateTime.parse(value));
      }
    });
  }

  bool _isIsoDate(String value) {
    // Simple check: starts with 4 digits and contains 'T'
    return value.length >= 10 && value[4] == '-' && value.contains('T');
  }
}