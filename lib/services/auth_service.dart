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

  // CORRIGIDO: Torna a verificação de admin mais robusta
  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;

    // Se já tivermos os dados do utilizador em cache, usa-os
    if (_currentUserModel != null && _currentUserModel!.id == user.uid) {
      return _currentUserModel!.role == 'admin';
    }

    // Se não, vai buscar os dados à base de dados
    final userModel = await getUser(user.uid);
    _currentUserModel = userModel; // Guarda os dados em cache para uso futuro
    return userModel?.role == 'admin';
  }

  Future<void> saveUserToken(String token) async {
    final user = currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  Future<String?> updateUserEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    try {
      final user = currentUser;
      if (user == null) return "Utilizador não autenticado.";
      if (user.email == null) return "Utilizador sem e-mail associado.";

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      await user.verifyBeforeUpdateEmail(newEmail);

      await _firestore.collection('users').doc(user.uid).update({
        'email': newEmail,
      });

      return null;
    } on FirebaseAuthException catch (e) {
      print("Erro ao alterar e-mail: ${e.code}");
      if (e.code == 'wrong-password') {
        return 'A palavra-passe atual está incorreta.';
      } else if (e.code == 'email-already-in-use') {
        return 'Este e-mail já está a ser utilizado por outra conta.';
      }
      return 'Ocorreu um erro. Tente novamente.';
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print("Erro ao enviar e-mail de redefinição: $e");
      return false;
    }
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
        'name_lowercase': name.toLowerCase(),
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
        'name_lowercase': name.toLowerCase(),
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
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (userDoc.exists && userDoc.data()?['isBanned'] == true) {
        await _auth.signOut();
        throw FirebaseAuthException(
            code: 'user-disabled', message: 'Esta conta foi banida.');
      }

      return userCredential;
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
