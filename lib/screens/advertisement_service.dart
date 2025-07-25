import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/banner_model.dart'; // Importa o modelo correto

class AdvertisementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Stream<QuerySnapshot> getActivePopupBanners() {
    return _firestore
        .collection('advertisements')
        .where('isActive', isEqualTo: true)
        .where('bannerType', isEqualTo: 'popup')
        .snapshots();
  }

  Stream<QuerySnapshot> getActiveBottomBanners() {
    return _firestore
        .collection('advertisements')
        .where('isActive', isEqualTo: true)
        .where('bannerType', isEqualTo: 'bottom')
        .snapshots();
  }

  Future<bool> addAdvertisement({
    required File imageFile,
    required String bannerType,
    required String name,
    String? targetUrl,
  }) async {
    try {
      final imageUrl = await _uploadAdImage(imageFile);
      if (imageUrl == null) return false;

      await _firestore.collection('advertisements').add({
        'imageUrl': imageUrl,
        'targetUrl': targetUrl ?? '',
        'bannerType': bannerType,
        'name': name,
        'isActive': true,
        'createdAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print("Erro ao adicionar publicidade: $e");
      return false;
    }
  }

  Future<void> deleteAdvertisement(String adId, String imageUrl) async {
    try {
      await _storage.refFromURL(imageUrl).delete();
      await _firestore.collection('advertisements').doc(adId).delete();
    } catch (e) {
      print("Erro ao apagar publicidade: $e");
    }
  }

  Future<File?> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  Future<String?> _uploadAdImage(File file) async {
    try {
      final ref =
          _storage.ref().child('advertisements/${const Uuid().v4()}.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Erro no upload da imagem de publicidade: $e");
      return null;
    }
  }
}
