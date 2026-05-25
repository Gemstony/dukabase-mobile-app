import 'package:cloud_firestore/cloud_firestore.dart';

enum MemberRole { owner, staff }

class ShopMemberModel {
  final String shopId;
  final String userId;
  final MemberRole role;
  final DateTime joinedAt;

  ShopMemberModel({
    required this.shopId,
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'userId': userId,
      'role': role.toString().split('.').last,  // fixed
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  factory ShopMemberModel.fromMap(Map<String, dynamic> map) {
    return ShopMemberModel(
      shopId: map['shopId'] as String,
      userId: map['userId'] as String,
      role: MemberRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
      ),
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
    );
  }
}