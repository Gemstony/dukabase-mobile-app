import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dukabase/core/models/shop_member_model.dart';

class InvitationModel {
  final String id;
  final String shopId;
  final String inviterId;
  final String inviteeEmail;
  final String inviteeUserId;
  final String shopName;          // stored in Firestore for display
  final MemberRole role;
  final String status;            // 'pending', 'accepted', 'declined'
  final DateTime createdAt;
  final DateTime? respondedAt;

  InvitationModel({
    required this.id,
    required this.shopId,
    required this.inviterId,
    required this.inviteeEmail,
    required this.inviteeUserId,
    required this.shopName,
    required this.role,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'inviterId': inviterId,
      'inviteeEmail': inviteeEmail,
      'inviteeUserId': inviteeUserId,
      'shopName': shopName,           // ✅ now stored
      'role': role.name,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  factory InvitationModel.fromMap(String id, Map<String, dynamic> map) {
    return InvitationModel(
      id: id,
      shopId: map['shopId'] as String,
      inviterId: map['inviterId'] as String,
      inviteeEmail: map['inviteeEmail'] as String,
      inviteeUserId: map['inviteeUserId'] as String,
      shopName: map['shopName'] as String? ?? 'Unknown Shop',   // fallback for old data
      role: MemberRole.values.firstWhere((e) => e.name == map['role']),
      status: map['status'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      respondedAt: (map['respondedAt'] as Timestamp?)?.toDate(),
    );
  }
}