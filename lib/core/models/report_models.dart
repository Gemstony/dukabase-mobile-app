class SalesReportItem {
  final DateTime date;
  final double totalSales;
  final int transactionCount;

  SalesReportItem({
    required this.date,
    required this.totalSales,
    required this.transactionCount,
  });
}

class TopProductItem {
  final String productId;
  final String productName;
  final double quantitySold;
  final double revenue;

  TopProductItem({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.revenue,
  });
}

class PurchaseReportItem {
  final DateTime date;
  final double totalPurchases;
  final int purchaseCount;

  PurchaseReportItem({
    required this.date,
    required this.totalPurchases,
    required this.purchaseCount,
  });
}

class ExpenseCategoryItem {
  final String category;
  final double totalAmount;

  ExpenseCategoryItem({
    required this.category,
    required this.totalAmount,
  });
}

class IncomeSummary {
  final double totalRevenue;
  final double totalCogs;
  final double totalExpenses;
  final double grossProfit;
  final double netProfit;

  IncomeSummary({
    required this.totalRevenue,
    required this.totalCogs,
    required this.totalExpenses,
    required this.grossProfit,
    required this.netProfit,
  });
}