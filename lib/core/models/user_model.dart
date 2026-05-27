import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { owner, staff, admin }

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final DateTime createdAt;
  final String? photoUrl;
  final String? phone;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.photoUrl,
    this.phone,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
  return {
    'id': id,
    'email': email,
    'name': name,
    'role': role.name,
    'createdAt': Timestamp.fromDate(createdAt), // ✅ convert to Timestamp
    'photoUrl': photoUrl,
    'phone': phone,
    'isActive': isActive,
  };
}

factory UserModel.fromMap(String id, Map<String, dynamic> map) {
  // Handle createdAt safely
  DateTime createdAt;
  final createdAtValue = map['createdAt'];
  if (createdAtValue is Timestamp) {
    createdAt = createdAtValue.toDate();
  } else if (createdAtValue is DateTime) {
    createdAt = createdAtValue;
  } else if (createdAtValue is String) {
    createdAt = DateTime.parse(createdAtValue);
  } else {
    createdAt = DateTime.now(); // fallback
  }
  return UserModel(
    id: id,
    email: map['email'] as String,
    name: map['name'] as String,
    role: UserRole.values.firstWhere(
      (e) => e.name == map['role'],
      orElse: () => UserRole.staff,
    ),
    createdAt: createdAt,
    photoUrl: map['photoUrl'] as String?,
    phone: map['phone'] as String?,
    isActive: map['isActive'] ?? true,
  );
}

  // Firestore serialization

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    DateTime? createdAt,
    String? photoUrl,
    String? phone,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
    );
  }
}
