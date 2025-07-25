import 'package:cloud_firestore/cloud_firestore.dart';

class AdvertisementModel {
  final String id;
  final String title;
  final String imageUrl;
  final String redirectUrl;
  final bool isPopup;
  final bool isBottomFixed;

  AdvertisementModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.redirectUrl,
    required this.isPopup,
    required this.isBottomFixed,
  });

  factory AdvertisementModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AdvertisementModel(
      id: doc.id,
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      redirectUrl: data['redirectUrl'] ?? '',
      isPopup: data['isPopup'] ?? false,
      isBottomFixed: data['isBottomFixed'] ?? false,
    );
  }
}
