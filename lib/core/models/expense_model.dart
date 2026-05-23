import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String shopId;
  final String description;
  final double amount;
  final String category;
  final String paymentMethodId;
  final String? referenceNumber; // optional invoice/ref number
  final String? note;
  final DateTime expenseDate;
  final DateTime createdAt;
  final String createdBy; // user ID

  ExpenseModel({
    required this.id,
    required this.shopId,
    required this.description,
    required this.amount,
    required this.category,
    required this.paymentMethodId,
    this.referenceNumber,
    this.note,
    required this.expenseDate,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'description': description,
      'amount': amount,
      'category': category,
      'paymentMethodId': paymentMethodId,
      'referenceNumber': referenceNumber,
      'note': note,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  factory ExpenseModel.fromMap(String id, Map<String, dynamic> map) {
    return ExpenseModel(
      id: id,
      shopId: map['shopId'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      paymentMethodId: map['paymentMethodId'] as String,
      referenceNumber: map['referenceNumber'] as String?,
      note: map['note'] as String?,
      expenseDate: (map['expenseDate'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] as String,
    );
  }
}