import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_member_model.dart';
import '../models/user_model.dart';
import '../models/invitation_model.dart';

class StaffService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all members of a shop
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

  /// Invite staff (creates invitation document)
  Future<({bool success, String message})> inviteStaff({
    required String shopId,
    required String email,
    required String inviterId,
    required MemberRole role,
  }) async {
    try {
      // Find existing user
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
      final inviteeUserId = existingUser.docs.first.id;

      // Check if already a member
      final memberDocId = '${shopId}_$inviteeUserId';
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

      // Check for pending invitation
      final pendingInvitation = await _firestore
          .collection('invitations')
          .where('shopId', isEqualTo: shopId)
          .where('inviteeUserId', isEqualTo: inviteeUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (pendingInvitation.docs.isNotEmpty) {
        return (
          success: false,
          message: 'An invitation is already pending for this user',
        );
      }

      // Create invitation
      final invitationRef = _firestore.collection('invitations').doc();
      final shopDoc = await _firestore.collection('shops').doc(shopId).get();
      final shopName = shopDoc.data()?['name'] ?? 'Unknown Shop';
      final invitation = InvitationModel(
        id: invitationRef.id,
        shopId: shopId,
        inviterId: inviterId,
        inviteeEmail: email,
        inviteeUserId: inviteeUserId,
        role: role,
        status: 'pending',
        createdAt: DateTime.now(),
        shopName: shopName,
      );
      await invitationRef.set(invitation.toMap());
      return (success: true, message: 'Invitation sent successfully');
    } catch (e) {
      return (success: false, message: 'Error: $e');
    }
  }

  /// Remove staff from shop
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

  /// Update member role
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

  /// Update user details (name, phone)
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

  /// Accept invitation
  Future<({bool success, String message})> acceptInvitation(
    String invitationId,
    String userId,
  ) async {
    try {
      final invitationRef = _firestore
          .collection('invitations')
          .doc(invitationId);
      final invitationDoc = await invitationRef.get();
      if (!invitationDoc.exists) {
        return (success: false, message: 'Invitation not found');
      }
      final invitation = InvitationModel.fromMap(
        invitationId,
        invitationDoc.data()!,
      );
      if (invitation.status != 'pending') {
        return (success: false, message: 'Invitation already processed');
      }
      if (invitation.inviteeUserId != userId) {
        return (success: false, message: 'This invitation is not for you');
      }
      // Create shop member
      final member = ShopMemberModel(
        shopId: invitation.shopId,
        userId: userId,
        role: invitation.role,
        joinedAt: DateTime.now(),
      );
      final batch = _firestore.batch();
      batch.set(
        _firestore
            .collection('shopMembers')
            .doc('${invitation.shopId}_$userId'),
        member.toMap(),
      );
      batch.update(invitationRef, {
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      return (success: true, message: 'Invitation accepted');
    } catch (e) {
      return (success: false, message: 'Error: $e');
    }
  }

  /// Decline invitation
  Future<({bool success, String message})> declineInvitation(
    String invitationId,
    String userId,
  ) async {
    try {
      final invitationRef = _firestore
          .collection('invitations')
          .doc(invitationId);
      final invitationDoc = await invitationRef.get();
      if (!invitationDoc.exists) {
        return (success: false, message: 'Invitation not found');
      }
      final invitation = InvitationModel.fromMap(
        invitationId,
        invitationDoc.data()!,
      );
      if (invitation.status != 'pending') {
        return (success: false, message: 'Invitation already processed');
      }
      if (invitation.inviteeUserId != userId) {
        return (success: false, message: 'This invitation is not for you');
      }
      await invitationRef.update({
        'status': 'declined',
        'respondedAt': FieldValue.serverTimestamp(),
      });
      return (success: true, message: 'Invitation declined');
    } catch (e) {
      return (success: false, message: 'Error: $e');
    }
  }

  /// Get pending invitations for a user
  Stream<List<InvitationModel>> getPendingInvitations(String userId) {
    return _firestore
        .collection('invitations')
        .where('inviteeUserId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InvitationModel.fromMap(doc.id, doc.data()))
              .where((inv) => inv.status == 'pending')
              .toList(),
        );
  }

  /// Get pending invitations for a specific shop (owner view)
  Stream<List<InvitationModel>> getPendingInvitationsForShop(String shopId) {
    return _firestore
        .collection('invitations')
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InvitationModel.fromMap(doc.id, doc.data()))
              .where((inv) => inv.status == 'pending')
              .toList(),
        );
  }

  /// Get all invitations (including history) for a shop (owner view)
  Stream<List<InvitationModel>> getAllInvitationsForShop(String shopId) {
    return _firestore
        .collection('invitations')
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map(
          (snapshot) {
            final list = snapshot.docs
                .map((doc) => InvitationModel.fromMap(doc.id, doc.data()))
                .toList();
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          }
        );
  }

  // In StaffService
  Stream<List<Map<String, dynamic>>> getPendingInvitationsWithShop(
    String userId,
  ) {
    return _firestore
        .collection('invitations')
        .where('inviteeUserId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final List<Map<String, dynamic>> result = [];
          for (var doc in snapshot.docs) {
            try {
              final inv = InvitationModel.fromMap(doc.id, doc.data());
              if (inv.status != 'pending') continue;
              
              // We use the shopName already stored in the invitation
              // Since the user is not a member yet, they don't have permission to read the shop doc directly.
              result.add({'invitation': inv, 'shopName': inv.shopName});
            } catch (e) {
              print('Error parsing invitation: $e');
            }
          }
          return result;
        });
  }
}
