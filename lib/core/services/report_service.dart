import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sale_model.dart';
import '../models/product_model.dart';
import '../models/report_models.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------- SALES REPORT ----------

  /// Get total sales and transaction count per day within date range.
  /// Uses Firestore aggregation queries where possible, otherwise fetches and aggregates client‑side.
  Future<List<SalesReportItem>> getDailySalesReport(
    String shopId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection('shops')
        .doc(shopId)
        .collection('sales')
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThanOrEqualTo: end)
        .orderBy('createdAt', descending: false)
        .get();

    final Map<String, SalesReportItem> dailyMap = {};
    for (var doc in snapshot.docs) {
      final sale = SaleModel.fromMap(doc.id, doc.data());
      final dateKey = sale.createdAt.toLocal().toString().split(' ')[0];
      if (!dailyMap.containsKey(dateKey)) {
        dailyMap[dateKey] = SalesReportItem(
          date: DateTime(
            sale.createdAt.year,
            sale.createdAt.month,
            sale.createdAt.day,
          ),
          totalSales: 0,
          transactionCount: 0,
        );
      }
      final current = dailyMap[dateKey]!;
      dailyMap[dateKey] = SalesReportItem(
        date: current.date,
        totalSales: current.totalSales + sale.totalAmount,
        transactionCount: current.transactionCount + 1,
      );
    }
    return dailyMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Get top selling products within date range (by quantity sold).
  Future<List<TopProductItem>> getTopSellingProducts(
    String shopId,
    DateTime start,
    DateTime end,
  ) async {
    // Get all sales in date range
    final salesSnapshot = await _firestore
        .collection('shops')
        .doc(shopId)
        .collection('sales')
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThanOrEqualTo: end)
        .get();

    final Map<String, ({String productName, double quantity, double revenue})>
    productMap = {};
    for (var saleDoc in salesSnapshot.docs) {
      // Get items for each sale (allowed by your rules)
      final itemsSnapshot = await saleDoc.reference.collection('items').get();
      for (var itemDoc in itemsSnapshot.docs) {
        final data = itemDoc.data();
        final productId = data['productId'] as String;
        final productName =
            data['productName'] as String? ?? 'Unknown'; // denormalized
        final quantity = (data['quantity'] as num).toDouble();
        final subtotal = (data['subtotal'] as num).toDouble();

        if (!productMap.containsKey(productId)) {
          productMap[productId] = (
            productName: productName,
            quantity: 0,
            revenue: 0,
          );
        }
        var current = productMap[productId]!;
        productMap[productId] = (
          productName: productName,
          quantity: current.quantity + quantity,
          revenue: current.revenue + subtotal,
        );
      }
    }
    var list = productMap.entries
        .map(
          (e) => TopProductItem(
            productId: e.key,
            productName: e.value.productName,
            quantitySold: e.value.quantity,
            revenue: e.value.revenue,
          ),
        )
        .toList();
    list.sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
    return list.take(10).toList();
  }

  /// Get paginated sales history.
  Stream<QuerySnapshot<Map<String, dynamic>>> getSalesHistory(
    String shopId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) {
    var query = _firestore
        .collection('shops')
        .doc(shopId)
        .collection('sales')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    return query.snapshots();
  }

  // ---------- PURCHASE REPORT ----------

  Future<List<PurchaseReportItem>> getDailyPurchaseReport(
    String shopId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection('shops')
        .doc(shopId)
        .collection('purchases')
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThanOrEqualTo: end)
        .orderBy('createdAt', descending: false)
        .get();

    final Map<String, PurchaseReportItem> dailyMap = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp).toDate();
      final dateKey = createdAt.toLocal().toString().split(' ')[0];
      final total = (data['totalAmount'] as num).toDouble();
      if (!dailyMap.containsKey(dateKey)) {
        dailyMap[dateKey] = PurchaseReportItem(
          date: DateTime(createdAt.year, createdAt.month, createdAt.day),
          totalPurchases: 0,
          purchaseCount: 0,
        );
      }
      final current = dailyMap[dateKey]!;
      dailyMap[dateKey] = PurchaseReportItem(
        date: current.date,
        totalPurchases: current.totalPurchases + total,
        purchaseCount: current.purchaseCount + 1,
      );
    }
    return dailyMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<List<TopProductItem>> getTopPurchasedProducts(
    String shopId,
    DateTime start,
    DateTime end,
  ) async {
    final purchasesSnapshot = await _firestore
        .collection('shops')
        .doc(shopId)
        .collection('purchases')
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThanOrEqualTo: end)
        .get();

    final Map<String, ({String productName, double quantity, double cost})>
    productMap = {};
    for (var purchaseDoc in purchasesSnapshot.docs) {
      final itemsSnapshot = await purchaseDoc.reference
          .collection('items')
          .get();
      for (var itemDoc in itemsSnapshot.docs) {
        final data = itemDoc.data();
        final productId = data['productId'] as String;
        final productName =
            data['productName'] as String? ?? 'Unknown'; // denormalized
        final quantity = (data['quantity'] as num).toDouble();
        final totalCost = (data['subtotal'] as num).toDouble();

        if (!productMap.containsKey(productId)) {
          productMap[productId] = (
            productName: productName,
            quantity: 0,
            cost: 0,
          );
        }
        var current = productMap[productId]!;
        productMap[productId] = (
          productName: productName,
          quantity: current.quantity + quantity,
          cost: current.cost + totalCost,
        );
      }
    }
    var list = productMap.entries
        .map(
          (e) => TopProductItem(
            productId: e.key,
            productName: e.value.productName,
            quantitySold: e.value.quantity,
            revenue: e.value.cost,
          ),
        )
        .toList();
    list.sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
    return list.take(10).toList();
  }

  Future<List<({String supplierId, String supplierName, double totalAmount})>>
  getSupplierPurchaseSummary(
    String shopId,
    DateTime start,
    DateTime end,
  ) async {
    final purchasesSnapshot = await _firestore
        .collection('shops')
        .doc(shopId)
        .collection('purchases')
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThanOrEqualTo: end)
        .get();

    final Map<String, ({String supplierName, double amount})> supplierMap = {};
    for (var doc in purchasesSnapshot.docs) {
      final data = doc.data();
      final supplierId = data['supplierId'] as String;
      final supplierName =
          data['supplierName'] as String? ?? 'Unknown'; // denormalized
      final amount = (data['totalAmount'] as num).toDouble();

      if (!supplierMap.containsKey(supplierId)) {
        supplierMap[supplierId] = (supplierName: supplierName, amount: 0);
      }
      var current = supplierMap[supplierId]!;
      supplierMap[supplierId] = (
        supplierName: supplierName,
        amount: current.amount + amount,
      );
    }
    var list = supplierMap.entries
        .map(
          (e) => (
            supplierId: e.key,
            supplierName: e.value.supplierName,
            totalAmount: e.value.amount,
          ),
        )
        .toList();
    list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return list;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getPurchaseHistory(
    String shopId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) {
    var query = _firestore
        .collection('shops')
        .doc(shopId)
        .collection('purchases')
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    return query.snapshots();
  }

  // ---------- EXPENSES REPORT ----------

  // ---------- EXPENSES REPORT ----------

  /// Get total expenses per category within date range.
  Future<List<ExpenseCategoryItem>> getExpensesByCategory(
    String shopId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection('shops')
        .doc(shopId)
        .collection('expenses')
        .where('expenseDate', isGreaterThanOrEqualTo: start)
        .where('expenseDate', isLessThanOrEqualTo: end)
        .get();

    final Map<String, double> categoryMap = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final category = data['category'] as String;
      final amount = (data['amount'] as num).toDouble();
      categoryMap[category] = (categoryMap[category] ?? 0) + amount;
    }
    return categoryMap.entries
        .map((e) => ExpenseCategoryItem(category: e.key, totalAmount: e.value))
        .toList();
  }

  /// Get paginated expenses list (for history).
  Stream<QuerySnapshot<Map<String, dynamic>>> getExpensesHistory(
    String shopId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) {
    var query = _firestore
        .collection('shops')
        .doc(shopId)
        .collection('expenses')
        .orderBy('expenseDate', descending: true)
        .limit(limit);
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    return query.snapshots();
  }

  // ---------- PRODUCT REPORT ----------

// ---------- PRODUCT REPORT ----------

/// Get list of all products with pagination.
Stream<QuerySnapshot<Map<String, dynamic>>> getProductsPaginated(
  String shopId, {
  int limit = 20,
  DocumentSnapshot? lastDocument,
}) {
  var query = _firestore
      .collection('shops')
      .doc(shopId)
      .collection('products')
      .orderBy('name')
      .limit(limit);
  if (lastDocument != null) {
    query = query.startAfterDocument(lastDocument);
  }
  return query.snapshots();
}

/// Get low stock products (client‑side filter, real‑time stream)
Stream<List<ProductModel>> getLowStockProductsStream(String shopId) {
  return _firestore
      .collection('shops')
      .doc(shopId)
      .collection('products')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
          .where((product) => product.currentStock <= product.lowStockAlert)
          .toList());
}

  // ---------- INCOME REPORT (Simplified) ----------
  // ---------- INCOME REPORT ----------
  Future<IncomeSummary> getIncomeSummary(
    String shopId,
    DateTime start,
    DateTime end,
  ) async {
    // 1. Total Revenue from Sales
    final salesSnapshot = await _firestore
        .collection('shops')
        .doc(shopId)
        .collection('sales')
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThanOrEqualTo: end)
        .get();
    double totalRevenue = 0;
    for (var doc in salesSnapshot.docs) {
      totalRevenue += (doc.data()['totalAmount'] as num).toDouble();
    }

    // 2. Total Expenses
    final expensesSnapshot = await _firestore
        .collection('shops')
        .doc(shopId)
        .collection('expenses')
        .where('expenseDate', isGreaterThanOrEqualTo: start)
        .where('expenseDate', isLessThanOrEqualTo: end)
        .get();
    double totalExpenses = 0;
    for (var doc in expensesSnapshot.docs) {
      totalExpenses += (doc.data()['amount'] as num).toDouble();
    }

    // 3. COGS (Cost of Goods Sold) – optional, can be heavy.
    // For simplicity, we'll compute from purchase items sold within the period.
    // Alternative: skip COGS or compute from sale items' batch costs.
    double totalCogs = 0;
    // Fetch all sale items and sum costPrice * quantity (if you stored costPrice in sale items)
    // This is a heavier operation; you may decide to skip or implement later.
    // We'll provide a placeholder that returns 0, but you can uncomment the following logic.
    
  for (var saleDoc in salesSnapshot.docs) {
    final itemsSnapshot = await saleDoc.reference.collection('items').get();
    for (var itemDoc in itemsSnapshot.docs) {
      final data = itemDoc.data();
      final batchId = data['batchId'];
      final productId = data['productId'];
      final quantity = (data['quantity'] as num).toDouble();
      // Fetch batch cost price
      final batchDoc = await _firestore
          .collection('shops')
          .doc(shopId)
          .collection('products')
          .doc(productId)
          .collection('batches')
          .doc(batchId)
          .get();
      if (batchDoc.exists) {
        final costPrice = (batchDoc.data()?['costPrice'] as num)?.toDouble() ?? 0;
        totalCogs += quantity * costPrice;
      }
    }
  }
  

    final grossProfit = totalRevenue - totalCogs;
    final netProfit = grossProfit - totalExpenses;

    return IncomeSummary(
      totalRevenue: totalRevenue,
      totalCogs: totalCogs,
      totalExpenses: totalExpenses,
      grossProfit: grossProfit,
      netProfit: netProfit,
    );
  }

  // Inside ReportService class, add a helper method:
  Future<String> _getProductName(String shopId, String productId) async {
    try {
      final doc = await _firestore
          .collection('shops')
          .doc(shopId)
          .collection('products')
          .doc(productId)
          .get();
      return doc.exists
          ? (doc.data()?['name'] as String? ?? 'Unknown')
          : 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<String> _getSupplierName(String shopId, String supplierId) async {
    try {
      final doc = await _firestore
          .collection('shops')
          .doc(shopId)
          .collection('suppliers')
          .doc(supplierId)
          .get();
      return doc.exists
          ? (doc.data()?['name'] as String? ?? 'Unknown')
          : 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }
}
