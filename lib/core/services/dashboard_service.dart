import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../models/dashboard_data.dart';
import '../models/product_model.dart';
import '../models/supplier_model.dart';

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get aggregated dashboard data for a shop (real‑time stream)
  Stream<DashboardData> getDashboardData(String shopId) {
    return Rx.combineLatest6(
      _getTodaySales(shopId),
      _getTodayExpenses(shopId),
      _getTodayRepayments(shopId),
      _getProductsLowStock(shopId),
      _getAllProducts(shopId),
      _getSuppliers(shopId),
      (
        todaySales,
        todayExpenses,
        todayRepayments,
        lowStockItems,
        allProducts,
        suppliers,
      ) {
        // Additional data that can be fetched separately
        return DashboardData(
          todaySales: todaySales,
          todayExpenses: todayExpenses,
          todayProfit: todaySales - todayExpenses,
          todayRepayments: todayRepayments,
          totalProducts: allProducts.length,
          lowStockProducts: lowStockItems.length,
          activeSuppliers: suppliers.length,
          activeCustomers: 0, // will be updated via separate stream
          totalOutstandingCredit: 0,
          totalPendingBills: 0,
          lowStockItems: lowStockItems,
        );
      },
    );
  }

  Stream<double> _getTodaySales(String shopId) {
    final start = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final end = start.add(const Duration(days: 1));
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('sales')
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThan: end)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.fold(
            0.0,
            (sum, doc) => sum + (doc.data()['totalAmount'] as num).toDouble(),
          ),
        );
  }

  Stream<double> _getTodayExpenses(String shopId) {
    final start = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final end = start.add(const Duration(days: 1));
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('expenses')
        .where('expenseDate', isGreaterThanOrEqualTo: start)
        .where('expenseDate', isLessThan: end)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.fold(
            0.0,
            (sum, doc) => sum + (doc.data()['amount'] as num).toDouble(),
          ),
        );
  }

  Stream<double> _getTodayRepayments(String shopId) {
    final start = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final end = start.add(const Duration(days: 1));
    // Use a periodic stream since getAllPayments is async
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('customers')
        .snapshots()
        .asyncMap((customerSnapshot) async {
          double total = 0;
          for (final customerDoc in customerSnapshot.docs) {
            final paymentsSnapshot = await customerDoc.reference
                .collection('payments')
                .where('createdAt', isGreaterThanOrEqualTo: start)
                .where('createdAt', isLessThan: end)
                .get();
            for (final paymentDoc in paymentsSnapshot.docs) {
              total += (paymentDoc.data()['amount'] as num).toDouble();
            }
          }
          return total;
        });
  }

  Stream<List<LowStockProduct>> _getProductsLowStock(String shopId) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('products')
        .snapshots()
        .map((snapshot) {
          final lowStock = <LowStockProduct>[];
          for (var doc in snapshot.docs) {
            final product = ProductModel.fromMap(doc.id, doc.data());
            if (product.currentStock <= product.lowStockAlert) {
              lowStock.add(
                LowStockProduct(
                  productId: product.id,
                  name: product.name,
                  currentStock: product.currentStock,
                  threshold: product.lowStockAlert,
                  unit: product.unit,
                ),
              );
            }
          }
          return lowStock;
        });
  }

  Stream<List<ProductModel>> _getAllProducts(String shopId) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('products')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<SupplierModel>> _getSuppliers(String shopId) {
    return _firestore
        .collection('shops')
        .doc(shopId)
        .collection('suppliers')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SupplierModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // Additional separate streams for customers and credit can be added later
}
