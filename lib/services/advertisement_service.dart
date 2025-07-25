import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/advertisement_model.dart';

class AdvertisementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadAdImage(File image, String fileName) async {
    try {
      final ref = _storage.ref().child('ad_images').child(fileName);
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading ad image: $e');
      rethrow;
    }
  }

  Future<void> addAdvertisement(Map<String, dynamic> adData) async {
    try {
      await _firestore.collection('advertisements').add(adData);
    } catch (e) {
      print('Error adding advertisement: $e');
      rethrow;
    }
  }

  Stream<List<AdvertisementModel>> getAdvertisements() {
    return _firestore.collection('advertisements').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AdvertisementModel.fromFirestore(doc);
      }).toList();
    });
  }

  Future<void> deleteAdvertisement(String id, String imageUrl) async {
    try {
      // Delete the document from Firestore
      await _firestore.collection('advertisements').doc(id).delete();

      // Delete the image from Firebase Storage
      if (imageUrl.isNotEmpty) {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      }
    } catch (e) {
      // Handle cases where the image might not exist in storage anymore
      if (e is FirebaseException && e.code == 'object-not-found') {
        print('Image not found in storage, but deleting Firestore entry.');
      } else {
        print('Error deleting advertisement: $e');
        rethrow;
      }
    }
  }

  // --- NOVA FUNÇÃO ---
  Future<void> updateAdvertisement(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('advertisements').doc(id).update(data);
    } catch (e) {
      print('Error updating advertisement: $e');
      rethrow;
    }
  }
  // --- FIM DA NOVA FUNÇÃO ---
}
