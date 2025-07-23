import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final String productId;
  final String productName;
  final String productImageUrl;
  final String buyerId;
  final String sellerId;
  final List<String> participants;
  final String lastMessage;
  final Timestamp lastMessageTimestamp;

  ChatRoomModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.buyerId,
    required this.sellerId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTimestamp,
  });

  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatRoomModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productImageUrl: data['productImageUrl'] ?? '',
      buyerId: data['buyerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTimestamp: data['lastMessageTimestamp'] ?? Timestamp.now(),
    );
  }
}
