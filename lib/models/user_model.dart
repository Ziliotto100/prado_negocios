import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? photoUrl;
  final String role; // <-- NOVO
  final bool isBanned; // <-- NOVO

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.photoUrl,
    this.role = 'user', // <-- NOVO
    this.isBanned = false, // <-- NOVO
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      address: data['address'],
      photoUrl: data['photoUrl'],
      role: data['role'] ?? 'user', // <-- NOVO
      isBanned: data['isBanned'] ?? false, // <-- NOVO
    );
  }
}
