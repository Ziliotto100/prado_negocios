import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import 'auth_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  Future<String> getOrCreateChatRoom(ProductModel product) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) throw Exception("Utilizador não autenticado");
    if (product.id == null) throw Exception("ID do produto inválido");

    final buyerId = currentUser.uid;
    final sellerId = product.userId;

    List<String> ids = [buyerId, sellerId];
    ids.sort();
    String chatRoomId = '${ids.join('_')}_${product.id!}';

    final chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);
    final docSnapshot = await chatRoomRef.get();

    if (!docSnapshot.exists) {
      await chatRoomRef.set({
        'productId': product.id,
        'productName': product.name,
        // CORRIGIDO: Usa a primeira imagem da lista de URLs
        'productImageUrl':
            product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
        'buyerId': buyerId,
        'sellerId': sellerId,
        'participants': [buyerId, sellerId],
        'lastMessage': '',
        'lastMessageTimestamp': Timestamp.now(),
      });
    }

    return chatRoomId;
  }

  Future<void> sendMessage(String chatRoomId, String text) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null || text.trim().isEmpty) return;

    final messageData = {
      'senderId': currentUser.uid,
      'text': text.trim(),
      'timestamp': Timestamp.now(),
    };

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);

    await _firestore.collection('chat_rooms').doc(chatRoomId).update({
      'lastMessage': text.trim(),
      'lastMessageTimestamp': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getChatMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserChats() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }
}
