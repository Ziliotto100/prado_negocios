import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  UserModel? _currentUserModel;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<bool> isAdmin() async {
    if (currentUser == null) return false;
    if (_currentUserModel != null &&
        _currentUserModel!.id == currentUser!.uid) {
      return _currentUserModel!.role == 'admin';
    }

    final user = await getUser(currentUser!.uid);
    _currentUserModel = user;
    return user?.role == 'admin';
  }

  Future<bool> toggleBanStatus(String userId, bool isCurrentlyBanned) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBanned': !isCurrentlyBanned,
      });
      return true;
    } catch (e) {
      print("Erro ao alterar o estado de banimento: $e");
      return false;
    }
  }

  // NOVO: Obtém todos os utilizadores banidos
  Stream<QuerySnapshot> getBannedUsers() {
    return _firestore
        .collection('users')
        .where('isBanned', isEqualTo: true)
        .snapshots();
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      final docSnapshot =
          await _firestore.collection('users').doc(userId).get();
      if (docSnapshot.exists) {
        return UserModel.fromFirestore(docSnapshot);
      }
    } catch (e) {
      print("Erro ao obter utilizador: $e");
    }
    return null;
  }

  Future<bool> updateUserProfile({
    required String name,
    required String phone,
    required String address,
    File? newPhoto,
  }) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      String? photoUrl;
      if (newPhoto != null) {
        photoUrl = await _uploadProfilePhoto(newPhoto, user.uid);
      }

      final userData = {
        'name': name,
        'phone': phone,
        'address': address,
        'name_lowercase': name.toLowerCase(), // Adiciona campo para pesquisa
        if (photoUrl != null) 'photoUrl': photoUrl,
      };

      await _firestore.collection('users').doc(user.uid).update(userData);
      _currentUserModel = null;
      return true;
    } catch (e) {
      print("Erro ao atualizar perfil: $e");
      return false;
    }
  }

  Future<String?> _uploadProfilePhoto(File photo, String userId) async {
    try {
      final storageRef = _storage
          .ref()
          .child('profile_photos/$userId/${const Uuid().v4()}.jpg');
      final uploadTask = await storageRef.putFile(photo);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print("Erro no upload da foto de perfil: $e");
      return null;
    }
  }

  Future<UserCredential?> signUpWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': Timestamp.now(),
        'phone': '',
        'address': '',
        'photoUrl': null,
        'role': 'user',
        'isBanned': false,
        'name_lowercase': name.toLowerCase(), // Adiciona campo para pesquisa
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("Erro no registo: ${e.message}");
      return null;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (userQuery.docs.isNotEmpty) {
        final userDoc = userQuery.docs.first;
        if (userDoc.data()['isBanned'] == true) {
          throw FirebaseAuthException(
              code: 'user-disabled', message: 'Esta conta foi banida.');
        }
      }
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      print("Erro no login: ${e.message}");
      return null;
    }
  }

  Future<void> signOut() async {
    _currentUserModel = null;
    await _auth.signOut();
  }
}
