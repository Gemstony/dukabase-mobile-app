import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { owner, staff, admin }

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final DateTime createdAt;
  final String? photoUrl;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.photoUrl,
    this.isActive = true,
  });

  // Firestore serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'createdAt': createdAt,
      'photoUrl': photoUrl,
      'isActive': isActive,
    };
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      email: map['email'] as String,
      name: map['name'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.staff,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(), // ✅ convert
      photoUrl: map['photoUrl'] as String?,
      isActive: map['isActive'] ?? true,
    );
  }
}
