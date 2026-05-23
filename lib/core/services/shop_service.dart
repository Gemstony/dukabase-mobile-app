import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_model.dart';
import '../models/shop_member_model.dart';
import '../models/user_model.dart';

class ShopService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new shop (owner automatically added as member)
  Future<ShopModel?> createShop({
    required String name,
    required String ownerId,
    String? address,
    String? phone,
    String? currency,
  }) async {
    try {
      final shopRef = _firestore.collection('shops').doc();
      final now = DateTime.now();
      final shop = ShopModel(
        id: shopRef.id,
        name: name,
        ownerId: ownerId,
        address: address,
        phone: phone,
        currency: currency ?? 'USD',
        createdAt: now,
      );
      await shopRef.set(shop.toMap());

      // Add owner as member
      final member = ShopMemberModel(
        shopId: shop.id,
        userId: ownerId,
        role: MemberRole.owner,
        joinedAt: now,
      );
      await _firestore
          .collection('shopMembers')
          .doc('${shop.id}_$ownerId')
          .set(member.toMap());

      return shop;
    } catch (e) {
      print('Create shop error: $e');
      return null;
    }
  }

  // Get all shops where current user is a member (owner or staff)
  Stream<List<ShopModel>> getUserShops(String userId) {
    print('🔍 getUserShops called for userId: $userId'); // debug
    return _firestore
        .collection('shopMembers')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .handleError((error) {
          print('❌ Error in shopMembers stream: $error');
          return Stream.error(error);
        })
        .asyncMap((memberSnapshot) async {
          print('📦 Found ${memberSnapshot.docs.length} shopMembers documents');
          final List<ShopModel> shops = [];
          for (var doc in memberSnapshot.docs) {
            try {
              final member = ShopMemberModel.fromMap(doc.data());
              final shopDoc = await _firestore
                  .collection('shops')
                  .doc(member.shopId)
                  .get();
              if (shopDoc.exists) {
                shops.add(ShopModel.fromMap(shopDoc.id, shopDoc.data()!));
                print('✅ Loaded shop: ${shopDoc.data()!['name']}');
              } else {
                print(
                  '⚠️ Shop document not found for shopId: ${member.shopId}',
                );
              }
            } catch (e) {
              print('❌ Error processing member document: $e');
            }
          }
          return shops;
        });
  }

  // Get shop members (for a given shop)
  Stream<List<({UserModel user, MemberRole role})>> getShopMembers(
    String shopId,
  ) {
    return _firestore
        .collection('shopMembers')
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .asyncMap((snapshot) async {
          final List<({UserModel user, MemberRole role})> members = [];
          for (var doc in snapshot.docs) {
            final member = ShopMemberModel.fromMap(doc.data());
            final userDoc = await _firestore
                .collection('users')
                .doc(member.userId)
                .get();
            if (userDoc.exists) {
              final user = UserModel.fromMap(userDoc.id, userDoc.data()!);
              members.add((user: user, role: member.role));
            }
          }
          return members;
        });
  }

  // Invite staff by email (if user exists, add to shopMembers; else create placeholder)
  Future<bool> inviteStaff({
    required String shopId,
    required String email,
    required String invitedByUserId,
  }) async {
    try {
      // Check if user with that email already exists
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      String userId;
      if (userQuery.docs.isEmpty) {
        // Create a placeholder user (inactive until they register)
        final newUserRef = _firestore.collection('users').doc();
        final placeholderUser = UserModel(
          id: newUserRef.id,
          email: email,
          name: email.split('@')[0], // temporary name
          role: UserRole.staff,
          createdAt: DateTime.now(),
          isActive: false, // not yet registered
        );
        await newUserRef.set(placeholderUser.toMap());
        userId = newUserRef.id;
      } else {
        userId = userQuery.docs.first.id;
      }

      // Check if already a member
      final memberDoc = await _firestore
          .collection('shopMembers')
          .doc('${shopId}_$userId')
          .get();
      if (memberDoc.exists) {
        return false; // already a member
      }

      // Add member with role staff
      final member = ShopMemberModel(
        shopId: shopId,
        userId: userId,
        role: MemberRole.staff,
        joinedAt: DateTime.now(),
      );
      await _firestore
          .collection('shopMembers')
          .doc('${shopId}_$userId')
          .set(member.toMap());

      return true;
    } catch (e) {
      print('Invite staff error: $e');
      return false;
    }
  }
}
