import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String shopId;
  final String customerId;
  final double amount;
  final String paymentMethodId;
  final String? saleId; // optional: which sale this payment is for (if any)
  final String note;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.shopId,
    required this.customerId,
    required this.amount,
    required this.paymentMethodId,
    this.saleId,
    this.note = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'customerId': customerId,
      'amount': amount,
      'paymentMethodId': paymentMethodId,
      'saleId': saleId,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PaymentModel.fromMap(String id, Map<String, dynamic> map) {
    return PaymentModel(
      id: id,
      shopId: map['shopId'] as String,
      customerId: map['customerId'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentMethodId: map['paymentMethodId'] as String,
      saleId: map['saleId'] as String?,
      note: map['note'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}