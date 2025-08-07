import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı durumu değişikliğini dinle
  Stream<User?> get userStream => _auth.authStateChanges();

  // Mevcut kullanıcıyı getir
  User? get currentUser => _auth.currentUser;

  // Email doğrulanmış mı kontrol et
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Giriş yap
  Future<User?> signIn(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Email doğrulanmamışsa hata fırlat
      if (result.user != null && !result.user!.emailVerified) {
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Email address not verified. Please check your inbox.',
        );
      }

      return result.user;
    } catch (e) {
      print('Giriş hatası: $e');
      rethrow;
    }
  }

// Kayıt ol - Basit ve güvenli versiyon
  Future<User?> signUp(
      String email, String password, String name, String nickname) async {
    try {
      // 1. Kullanıcıyı oluştur
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user == null) {
        throw Exception('User creation failed');
      }

      final user = result.user!;
      final userId = user.uid;

      // 2. Kullanıcı bilgilerini güncelle (hata varsa devam et)
      try {
        await user.updateDisplayName(name);
        print('Display name güncellendi');
      } catch (e) {
        print('Display name güncellenirken hata (devam ediliyor): $e');
      }

      // 3. Firestore'a kaydet
      final userData = {
        'email': email,
        'name': name,
        'nickname': nickname,
        'bio': '',
        'createdAt': DateTime.now(),
        'favoriteNews': [],
        'followers': [],
        'following': [],
        'profileImageUrl': '',
        'unreadNotificationCount': 0,
        'emailVerified': false,
        'privacySettings': {
          'analyticsEnabled': true,
          'crashReportsEnabled': true,
          'personalizedAdsEnabled': false,
        },
      };

      await _firestore.collection('users').doc(userId).set(userData);
      print('Firestore kayıt tamamlandı');

      // 4. Email doğrulama gönder
      try {
        await user.sendEmailVerification();
        print('Email doğrulama gönderildi');
      } catch (e) {
        print('Email doğrulama gönderilirken hata (devam ediliyor): $e');
      }

      // 5. Çıkış yap
      await _auth.signOut();
      print('Kullanıcı çıkış yaptırıldı');

      return user;
    } catch (e) {
      print('Kayıt hatası: $e');
      rethrow;
    }
  }

  // Email doğrulama mailini yeniden gönder
  Future<void> resendEmailVerification(
      {String? email, String? password}) async {
    try {
      User? user = _auth.currentUser;

      // Eğer mevcut kullanıcı yoksa ve email/password verilmişse, geçici olarak giriş yap
      if (user == null && email != null && password != null) {
        final UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = result.user;
      }

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        // Eğer geçici giriş yaptıysak, tekrar çıkış yap
        if (email != null && password != null) {
          await _auth.signOut();
        }
      }
    } catch (e) {
      print('Email doğrulama gönderme hatası: $e');
      rethrow;
    }
  }

  // Email doğrulama durumunu kontrol et ve güncelle
  Future<bool> checkEmailVerification({String? email, String? password}) async {
    try {
      User? user = _auth.currentUser;

      // Eğer mevcut kullanıcı yoksa ve email/password verilmişse, geçici olarak giriş yap
      if (user == null && email != null && password != null) {
        try {
          final UserCredential result = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          user = result.user;
        } catch (e) {
          // Giriş yapılamadıysa false döndür
          return false;
        }
      }

      if (user != null) {
        await user.reload(); // Kullanıcı bilgilerini yenile
        user = _auth.currentUser; // Güncellenmiş kullanıcıyı al

        if (user != null && user.emailVerified) {
          // Firestore'da email doğrulama durumunu güncelle
          await _firestore.collection('users').doc(user.uid).update({
            'emailVerified': true,
          });

          // Eğer geçici giriş yaptıysak, kullanıcıyı giriş yapmış durumda bırak
          // Çünkü email doğrulandı, artık giriş yapabilir
          return true;
        } else {
          // Email henüz doğrulanmamışsa ve geçici giriş yaptıysak çıkış yap
          if (email != null && password != null && user != null) {
            await _auth.signOut();
          }
        }
      }
      return false;
    } catch (e) {
      print('Email doğrulama kontrol hatası: $e');
      return false;
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

  // Şifre değiştirme
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null && user.email != null) {
        // Önce mevcut şifreyi doğrula
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(credential);

        // Yeni şifreyi güncelle
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      print('Şifre değiştirme hatası: $e');
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

  // Bio güncelleme
  Future<void> updateBio(String bio) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'bio': bio,
        });
      }
    } catch (e) {
      print('Bio güncelleme hatası: $e');
      rethrow;
    }
  }

  Future<void> updateProfileImage(String imageUrl) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'profileImageUrl': imageUrl,
        });
      }
    } catch (e) {
      print('Profil resmi güncelleme hatası: $e');
      rethrow;
    }
  }

  // Privacy Settings

  // Privacy ayarlarını getir
  Future<Map<String, bool>> getPrivacySettings() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('privacySettings')) {
          Map<String, dynamic> privacySettings = data['privacySettings'];
          return {
            'analyticsEnabled': privacySettings['analyticsEnabled'] ?? true,
            'crashReportsEnabled':
                privacySettings['crashReportsEnabled'] ?? true,
            'personalizedAdsEnabled':
                privacySettings['personalizedAdsEnabled'] ?? false,
          };
        }
      }

      // Varsayılan değerler
      return {
        'analyticsEnabled': true,
        'crashReportsEnabled': true,
        'personalizedAdsEnabled': false,
      };
    } catch (e) {
      print('Privacy ayarları getirme hatası: $e');
      return {
        'analyticsEnabled': true,
        'crashReportsEnabled': true,
        'personalizedAdsEnabled': false,
      };
    }
  }

  // Privacy ayarını güncelle
  Future<void> updatePrivacySetting(String setting, bool value) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'privacySettings.$setting': value,
        });

        // SharedPreferences'a da kaydet (yerel erişim için)
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('privacy_$setting', value);
      }
    } catch (e) {
      print('Privacy ayarı güncelleme hatası: $e');
      rethrow;
    }
  }

  // Tüm privacy ayarlarını güncelle
  Future<void> updateAllPrivacySettings({
    required bool analyticsEnabled,
    required bool crashReportsEnabled,
    required bool personalizedAdsEnabled,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'privacySettings': {
            'analyticsEnabled': analyticsEnabled,
            'crashReportsEnabled': crashReportsEnabled,
            'personalizedAdsEnabled': personalizedAdsEnabled,
          },
        });

        // SharedPreferences'a da kaydet
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('privacy_analyticsEnabled', analyticsEnabled);
        await prefs.setBool('privacy_crashReportsEnabled', crashReportsEnabled);
        await prefs.setBool(
            'privacy_personalizedAdsEnabled', personalizedAdsEnabled);
      }
    } catch (e) {
      print('Privacy ayarları güncelleme hatası: $e');
      rethrow;
    }
  }

  // Hesap silme
  Future<void> deleteAccount(String password) async {
    try {
      User? user = _auth.currentUser;
      if (user != null && user.email != null) {
        // Önce kullanıcıyı yeniden doğrula
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );

        await user.reauthenticateWithCredential(credential);

        // Firestore'dan kullanıcı verilerini sil
        await _firestore.collection('users').doc(user.uid).delete();

        // Son olarak Authentication'dan sil
        await user.delete();

        // SharedPreferences'ı temizle
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
    } catch (e) {
      print('Hesap silme hatası: $e');
      rethrow;
    }
  }

  // Veri indirme (GDPR uyumluluğu için)
  Future<Map<String, dynamic>> exportUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Hassas bilgileri çıkar
        userData.remove('password');

        return {
          'exportDate': DateTime.now().toIso8601String(),
          'userId': user.uid,
          'userInfo': userData,
        };
      }

      return {};
    } catch (e) {
      print('Veri export hatası: $e');
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
