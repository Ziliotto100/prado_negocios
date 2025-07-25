import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String imageUrl;
  final String? targetUrl;
  final String bannerType;
  final String name;
  final Timestamp createdAt;

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.targetUrl,
    required this.bannerType,
    required this.name,
    required this.createdAt,
  });

  factory BannerModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BannerModel(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      targetUrl: data['targetUrl'],
      bannerType: data['bannerType'] ?? 'popup',
      name: data['name'] ?? 'Banner sem nome',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
