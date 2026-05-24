import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, String currencyCode) {
    final format = NumberFormat.currency(
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  static String _getCurrencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'TZS': return 'TSh';
      case 'KES': return 'KSh';
      case 'NGN': return '₦';
      default: return code;
    }
  }
}