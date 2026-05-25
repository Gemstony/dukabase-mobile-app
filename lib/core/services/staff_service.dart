import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_member_model.dart';
import '../models/user_model.dart';

class StaffService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all members (staff + owners) of a shop, excluding the owner who is currently logged in? We'll include all.
  Stream<List<({UserModel user, MemberRole role, DateTime joinedAt})>>
  getShopMembers(String shopId) {
    return _firestore
        .collection('shopMembers')
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .asyncMap((snapshot) async {
          final List<({UserModel user, MemberRole role, DateTime joinedAt})>
          members = [];
          for (var doc in snapshot.docs) {
            final member = ShopMemberModel.fromMap(doc.data());
            final userDoc = await _firestore
                .collection('users')
                .doc(member.userId)
                .get();
            if (userDoc.exists) {
              final user = UserModel.fromMap(userDoc.id, userDoc.data()!);
              members.add((
                user: user,
                role: member.role,
                joinedAt: member.joinedAt,
              ));
            }
          }
          return members;
        });
  }

  /// Invite a staff member by email.
  /// If user does not exist, create a placeholder account (inactive, no password).
  /// Returns (success, message).
  Future<({bool success, String message})> inviteStaff({
    required String shopId,
    required String email,
    required String invitedByUserId,
    required MemberRole role,
  }) async {
    try {
      // 1. Find existing user (no placeholder creation)
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (existingUser.docs.isEmpty) {
        return (
          success: false,
          message: 'No user found with this email. User must register first.',
        );
      }
      final userId = existingUser.docs.first.id;

      // 2. Check if already a member
      final memberDocId = '${shopId}_$userId';
      final existingMember = await _firestore
          .collection('shopMembers')
          .doc(memberDocId)
          .get();
      if (existingMember.exists) {
        return (
          success: false,
          message: 'User is already a member of this shop',
        );
      }

      // 3. Add to shopMembers
      final member = ShopMemberModel(
        shopId: shopId,
        userId: userId,
        role: role,
        joinedAt: DateTime.now(),
      );
      await _firestore
          .collection('shopMembers')
          .doc(memberDocId)
          .set(member.toMap());
      return (success: true, message: 'Staff invited successfully');
    } catch (e) {
      return (success: false, message: 'Error: $e');
    }
  }

  /// Remove a staff member from the shop (delete from shopMembers).
  Future<bool> removeStaff(String shopId, String userId) async {
    try {
      await _firestore
          .collection('shopMembers')
          .doc('${shopId}_$userId')
          .delete();
      return true;
    } catch (e) {
      print('Remove staff error: $e');
      return false;
    }
  }

  Future<bool> updateMemberRole(
    String shopId,
    String userId,
    MemberRole newRole,
  ) async {
    try {
      await _firestore
          .collection('shopMembers')
          .doc('${shopId}_$userId')
          .update({'role': newRole.name});
      return true;
    } catch (e) {
      print('Update role error: $e');
      return false;
    }
  }

  /// Update user details (name, phone, email) – only for existing users.
  Future<bool> updateUserDetails(
    String userId, {
    String? name,
    String? phone,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updates);
      }
      return true;
    } catch (e) {
      print('Update user error: $e');
      return false;
    }
  }
}
