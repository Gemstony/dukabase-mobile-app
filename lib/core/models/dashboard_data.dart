class DashboardData {
  final double todaySales;
  final double todayExpenses;
  final double todayProfit; // todaySales - todayExpenses (simplified; COGS later)
  final int totalProducts;
  final int lowStockProducts;
  final int activeSuppliers;
  final int activeCustomers;
  final double totalOutstandingCredit; // sum of customer balances positive
  final double totalPendingBills; // sum of purchase balances positive (money owed to suppliers)
  final List<LowStockProduct> lowStockItems;

  DashboardData({
    required this.todaySales,
    required this.todayExpenses,
    required this.todayProfit,
    required this.totalProducts,
    required this.lowStockProducts,
    required this.activeSuppliers,
    required this.activeCustomers,
    required this.totalOutstandingCredit,
    required this.totalPendingBills,
    required this.lowStockItems,
  });
}

class LowStockProduct {
  final String productId;
  final String name;
  final double currentStock;
  final double threshold;
  final String unit;

  LowStockProduct({
    required this.productId,
    required this.name,
    required this.currentStock,
    required this.threshold,
    required this.unit,
  });
}