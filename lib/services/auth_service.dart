import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı durumu değişikliğini dinle
  Stream<User?> get userStream => _auth.authStateChanges();

  // Mevcut kullanıcıyı getir
  User? get currentUser => _auth.currentUser;

  // Giriş yap
  Future<User?> signIn(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Giriş hatası: $e');
      rethrow;
    }
  }

  // Kayıt ol
  Future<User?> signUp(
      String email, String password, String name, String nickname) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı bilgilerini Firestore'a kaydet
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'name': name,
        'nickname': nickname,
        'createdAt': DateTime.now(),
        'favoriteNews': [],
        'followers': [],
        'following': [],
        'profileImageUrl': '',
      });

      // Kullanıcı profilini güncelle
      await result.user!.updateDisplayName(name);

      return result.user;
    } catch (e) {
      print('Kayıt hatası: $e');
      rethrow;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print('Çıkış hatası: $e');
      rethrow;
    }
  }

  // Şifre sıfırlama
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Şifre sıfırlama hatası: $e');
      rethrow;
    }
  }

  // Profil güncelleme
  Future<void> updateProfile(String name, {String? nickname}) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(name);

        final updateData = {'name': name};
        if (nickname != null) {
          updateData['nickname'] = nickname;
        }

        await _firestore.collection('users').doc(user.uid).update(updateData);
      }
    } catch (e) {
      print('Profil güncelleme hatası: $e');
      rethrow;
    }
  }

  Future<void> updateProfileImage(String imageUrl) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Update Firestore document with profile image
        await _firestore.collection('users').doc(user.uid).update({
          'profileImageUrl': imageUrl,
        });
      }
    } catch (e) {
      print('Profil resmi güncelleme hatası: $e');
      rethrow;
    }
  }

  // Kullanıcıyı takip et
  Future<void> followUser(String targetUserId) async {
    final currentUserId = _auth.currentUser!.uid;

    await _firestore.collection('users').doc(currentUserId).update({
      'following': FieldValue.arrayUnion([targetUserId]),
    });

    await _firestore.collection('users').doc(targetUserId).update({
      'followers': FieldValue.arrayUnion([currentUserId]),
    });
  }

// Takibi bırak
  Future<void> unfollowUser(String targetUserId) async {
    final currentUserId = _auth.currentUser!.uid;

    await _firestore.collection('users').doc(currentUserId).update({
      'following': FieldValue.arrayRemove([targetUserId]),
    });

    await _firestore.collection('users').doc(targetUserId).update({
      'followers': FieldValue.arrayRemove([currentUserId]),
    });
  }

// Kullanıcı bilgilerini getir
  Future<DocumentSnapshot> getUserInfo(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }
}
