import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Existing method
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      } else {
        // Create a default profile if it doesn't exist
        final defaultProfile = {
          'name': '',
          'email': '',
          'photoUrl': null,
          'createdAt': FieldValue.serverTimestamp(),
        };
        await _firestore.collection('users').doc(userId).set(defaultProfile);
        return defaultProfile;
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  // Add this method
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }
}
