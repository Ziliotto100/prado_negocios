import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import 'auth_service.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  Future<List<ProductModel>> getFeaturedProductsOnce() async {
    final snapshot = await _firestore
        .collection('products')
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
  }

  Future<void> toggleFeaturedStatus(
      String productId, bool isCurrentlyFeatured) async {
    await _firestore.collection('products').doc(productId).update({
      'isFeatured': !isCurrentlyFeatured,
    });
  }

  Stream<QuerySnapshot> getFeaturedProducts() {
    return _firestore
        .collection('products')
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<bool> addProduct({
    required List<File> imageFiles,
    required String name,
    required String description,
    required double price,
    required String category,
    required String city,
  }) async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception("Utilizador não autenticado.");

      List<String> imageUrls = [];
      for (var file in imageFiles) {
        final url = await _uploadCompressedImage(file);
        if (url != null) {
          imageUrls.add(url);
        }
      }

      if (imageUrls.isEmpty) throw Exception("Falha no upload das imagens.");

      final newProduct = ProductModel(
        name: name,
        description: description,
        price: price,
        imageUrls: imageUrls,
        userId: user.uid,
        category: category,
        city: city,
        createdAt: Timestamp.now(),
        favoritedBy: [],
        isFeatured: false,
      );

      final productData = newProduct.toMap();
      productData['name_lowercase'] = name.toLowerCase();

      await _firestore.collection('products').add(productData);
      return true;
    } catch (e) {
      print("Erro ao adicionar produto: $e");
      return false;
    }
  }

  Future<bool> updateProduct({
    required ProductModel originalProduct,
    required String newName,
    required String newDescription,
    required double newPrice,
    required String newCategory,
    required String newCity,
    File? newImageFile,
  }) async {
    try {
      List<String> imageUrls = originalProduct.imageUrls;

      if (newImageFile != null) {
        final newImageUrl = await _uploadCompressedImage(newImageFile);
        if (newImageUrl != null) {
          if (originalProduct.imageUrls.isNotEmpty) {
            await _storage.refFromURL(originalProduct.imageUrls.first).delete();
          }
          imageUrls = [newImageUrl];
        }
      }

      final updatedData = {
        'name': newName,
        'description': newDescription,
        'price': newPrice,
        'imageUrls': imageUrls,
        'category': newCategory,
        'city': newCity,
        'name_lowercase': newName.toLowerCase(),
      };

      await _firestore
          .collection('products')
          .doc(originalProduct.id)
          .update(updatedData);
      return true;
    } catch (e) {
      print("Erro ao editar produto: $e");
      return false;
    }
  }

  Future<void> toggleFavoriteStatus(
      String productId, bool isCurrentlyFavorited) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final productRef = _firestore.collection('products').doc(productId);

    if (isCurrentlyFavorited) {
      await productRef.update({
        'favoritedBy': FieldValue.arrayRemove([user.uid])
      });
    } else {
      await productRef.update({
        'favoritedBy': FieldValue.arrayUnion([user.uid])
      });
    }
  }

  Stream<QuerySnapshot> getFavoriteProducts() {
    final user = _authService.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('products')
        .where('favoritedBy', arrayContains: user.uid)
        .snapshots();
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    if (query.isEmpty) return [];

    final snapshot = await _firestore
        .collection('products')
        .where('name_lowercase', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('name_lowercase',
            isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
        .get();

    return snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
  }

  Future<bool> deleteProduct(ProductModel product) async {
    try {
      for (var url in product.imageUrls) {
        await _storage.refFromURL(url).delete();
      }
      await _firestore.collection('products').doc(product.id).delete();
      return true;
    } catch (e) {
      print("Erro ao apagar produto: $e");
      return false;
    }
  }

  Stream<QuerySnapshot> getProductsForCurrentUser() {
    final user = _authService.currentUser;
    if (user == null) return const Stream.empty();
    return _getProductsByUserId(user.uid);
  }

  Stream<QuerySnapshot> getProductsForUser(String userId) {
    return _getProductsByUserId(userId);
  }

  Stream<QuerySnapshot> _getProductsByUserId(String userId) {
    return _firestore
        .collection('products')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<List<File>> pickImages() async {
    final pickedFiles =
        await _picker.pickMultiImage(imageQuality: 80, maxWidth: 1024);
    return pickedFiles.map((xfile) => File(xfile.path)).toList();
  }

  Future<String?> _uploadCompressedImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final path = tempDir.path;
      final randomFileName = const Uuid().v4();

      img.Image? originalImage = img.decodeImage(await file.readAsBytes());
      if (originalImage == null) return null;

      img.Image resizedImage = img.copyResize(originalImage, width: 1024);

      File compressedImageFile = File('$path/$randomFileName.jpg')
        ..writeAsBytesSync(img.encodeJpg(resizedImage, quality: 85));

      final storageRef =
          _storage.ref().child('product_images/${const Uuid().v4()}.jpg');

      final uploadTask = await storageRef.putFile(compressedImageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print("Erro na compressão/upload: $e");
      return null;
    }
  }
}
