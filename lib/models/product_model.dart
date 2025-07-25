import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String? id;
  final String name;
  final String description;
  final double price;
  final List<String> imageUrls;
  final String userId;
  final String category;
  final String city;
  final String condition;
  final Timestamp createdAt;
  final List<String> favoritedBy;

  ProductModel({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrls,
    required this.userId,
    required this.category,
    required this.city,
    required this.condition,
    required this.createdAt,
    required this.favoritedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrls': imageUrls,
      'userId': userId,
      'category': category,
      'city': city,
      'condition': condition,
      'createdAt': createdAt,
      'favoritedBy': favoritedBy,
    };
  }

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      userId: data['userId'] ?? '',
      category: data['category'] ?? 'Outros',
      city: data['city'] ?? 'Antônio Prado',
      condition: data['condition'] ?? 'Não especificado',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      favoritedBy: List<String>.from(data['favoritedBy'] ?? []),
    );
  }
}
