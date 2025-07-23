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
  final ImagePicker _picker = ImagePicker();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

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

  // NOVO: Atualizar os dados do perfil do utilizador
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
        if (photoUrl != null) 'photoUrl': photoUrl,
      };

      await _firestore.collection('users').doc(user.uid).update(userData);
      return true;
    } catch (e) {
      print("Erro ao atualizar perfil: $e");
      return false;
    }
  }

  // NOVO: Função para fazer o upload da foto de perfil
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
        'phone': '', // Campos iniciais vazios
        'address': '',
        'photoUrl': null,
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
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      print("Erro no login: ${e.message}");
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
