import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseFavoritesService {
  static final FirebaseFavoritesService _instance =
      FirebaseFavoritesService._internal();
  factory FirebaseFavoritesService() => _instance;
  FirebaseFavoritesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Kullanıcının favori kriptolarını getir
  Future<Set<String>> getFavoriteCryptos() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc('cryptos')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final favoritesList = data['favorites'] as List<dynamic>?;
        return Set<String>.from(favoritesList ?? []);
      }
      return <String>{};
    } catch (e) {
      throw Exception('Failed to load favorites: $e');
    }
  }

  // Favori kripto ekle
  Future<void> addFavoriteCrypto(String cryptoId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final docRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc('cryptos');

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        Set<String> favorites = <String>{};
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final favoritesList = data['favorites'] as List<dynamic>?;
          favorites = Set<String>.from(favoritesList ?? []);
        }

        favorites.add(cryptoId);

        transaction.set(
            docRef,
            {
              'favorites': favorites.toList(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      });
    } catch (e) {
      throw Exception('Failed to add favorite: $e');
    }
  }

  // Favori kriptoyu kaldır
  Future<void> removeFavoriteCrypto(String cryptoId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final docRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc('cryptos');

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        Set<String> favorites = <String>{};
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final favoritesList = data['favorites'] as List<dynamic>?;
          favorites = Set<String>.from(favoritesList ?? []);
        }

        favorites.remove(cryptoId);

        transaction.set(
            docRef,
            {
              'favorites': favorites.toList(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      });
    } catch (e) {
      throw Exception('Failed to remove favorite: $e');
    }
  }

  // Favori durumunu toggle et
  Future<void> toggleFavoriteCrypto(String cryptoId) async {
    final favorites = await getFavoriteCryptos();

    if (favorites.contains(cryptoId)) {
      await removeFavoriteCrypto(cryptoId);
    } else {
      await addFavoriteCrypto(cryptoId);
    }
  }

  // Favori kriptolar listesini dinle (realtime updates için)
  Stream<Set<String>> watchFavoriteCryptos() {
    if (currentUserId == null) {
      return Stream.value(<String>{});
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .doc('cryptos')
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final favoritesList = data['favorites'] as List<dynamic>?;
        return Set<String>.from(favoritesList ?? []);
      }
      return <String>{};
    });
  }

  // Kullanıcı çıkış yaptığında cache'i temizle
  void clearCache() {
    // Bu method kullanıcı logout olduğunda çağrılabilir
  }

  // Offline durumda favorileri local storage'dan al (fallback)
  Future<Set<String>> getFavoritesFromLocal() async {
    // Bu method internet bağlantısı olmadığında kullanılabilir
    // SharedPreferences ile local cache implementasyonu
    try {
      // Local cache implementasyonu buraya eklenebilir
      return <String>{};
    } catch (e) {
      return <String>{};
    }
  }

  // Batch operations için (çoklu favori ekleme/çıkarma)
  Future<void> batchUpdateFavorites({
    List<String>? toAdd,
    List<String>? toRemove,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final docRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc('cryptos');

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        Set<String> favorites = <String>{};
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final favoritesList = data['favorites'] as List<dynamic>?;
          favorites = Set<String>.from(favoritesList ?? []);
        }

        // Eklenecekleri ekle
        if (toAdd != null) {
          favorites.addAll(toAdd);
        }

        // Çıkarılacakları çıkar
        if (toRemove != null) {
          favorites.removeAll(toRemove);
        }

        transaction.set(
            docRef,
            {
              'favorites': favorites.toList(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      });
    } catch (e) {
      throw Exception('Failed to batch update favorites: $e');
    }
  }
}
