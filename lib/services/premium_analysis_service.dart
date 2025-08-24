// services/premium_analysis_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalysisHistoryItem {
  final String id;
  final String coinName;
  final String coinSymbol;
  final double price;
  final String analysis;
  final Map<String, dynamic> technicalData;
  final DateTime timestamp;

  AnalysisHistoryItem({
    required this.id,
    required this.coinName,
    required this.coinSymbol,
    required this.price,
    required this.analysis,
    required this.technicalData,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coinName': coinName,
      'coinSymbol': coinSymbol,
      'price': price,
      'analysis': analysis,
      'technicalData': technicalData,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static AnalysisHistoryItem fromJson(Map<String, dynamic> json) {
    return AnalysisHistoryItem(
      id: json['id'],
      coinName: json['coinName'],
      coinSymbol: json['coinSymbol'],
      price: json['price'].toDouble(),
      analysis: json['analysis'],
      technicalData: Map<String, dynamic>.from(json['technicalData'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class PremiumAnalysisService {
  static const String _historyKey = 'analysis_history';
  static const String _premiumKey = 'is_premium_user';
  static const String _dailyAnalysisKey = 'daily_analysis_count';
  static const String _lastAnalysisDateKey = 'last_analysis_date';

  static const int _maxHistoryItems = 50; // Premium kullanıcılar için 50 analiz
  static const int _freeAnalysisLimit =
      1; // Ücretsiz kullanıcılar için günlük 1 analiz
  static const int _freeHistoryLimit =
      5; // Ücretsiz kullanıcılar için 5 geçmiş analiz

  // Firebase instances
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  // Mevcut kullanıcının UID'sini al
  static String? get _currentUserId => _auth.currentUser?.uid;

  // Premium durumunu kontrol et (önce Firebase'den, yoksa local'den)
  static Future<bool> isPremiumUser() async {
    try {
      // Eğer kullanıcı giriş yapmışsa Firebase'den kontrol et
      if (_currentUserId != null) {
        final userDoc =
            await _firestore.collection('users').doc(_currentUserId).get();

        if (userDoc.exists) {
          final isPremium = userDoc.data()?['isPremium'] ?? false;
          // Local'e de kaydet (cache için)
          await _setPremiumStatusLocal(isPremium);
          return isPremium;
        }
      }

      // Firebase'de veri yoksa veya kullanıcı giriş yapmamışsa local'den al
      return await _getPremiumStatusLocal();
    } catch (e) {
      print('Error checking premium status from Firebase: $e');
      // Firebase hatası durumunda local'den al
      return await _getPremiumStatusLocal();
    }
  }

  // Premium durumunu Firebase'e kaydet
  static Future<void> setPremiumStatus(bool isPremium) async {
    try {
      // Önce local'e kaydet
      await _setPremiumStatusLocal(isPremium);

      // Eğer kullanıcı giriş yapmışsa Firebase'e de kaydet
      if (_currentUserId != null) {
        await _firestore.collection('users').doc(_currentUserId).set({
          'isPremium': isPremium,
          'premiumUpdatedAt': FieldValue.serverTimestamp(),
          'lastActiveAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print('Premium status saved to Firebase: $isPremium');
      }
    } catch (e) {
      print('Error saving premium status to Firebase: $e');
      // Firebase hatası olsa bile local kayıt başarılı olmuştur
    }
  }

  // Firebase'den kullanıcı verilerini senkronize et
  static Future<void> syncUserDataFromFirebase() async {
    try {
      if (_currentUserId == null) return;

      final userDoc =
          await _firestore.collection('users').doc(_currentUserId).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final isPremium = data['isPremium'] ?? false;

        // Local'e kaydet
        await _setPremiumStatusLocal(isPremium);

        print('User data synced from Firebase. Premium: $isPremium');
      }
    } catch (e) {
      print('Error syncing user data from Firebase: $e');
    }
  }

  // Kullanıcı premium durumunu Firebase'de başlat (ilk kayıt)
  static Future<void> initializeUserInFirebase() async {
    try {
      if (_currentUserId == null) return;

      final userDoc =
          await _firestore.collection('users').doc(_currentUserId).get();

      if (!userDoc.exists) {
        // Yeni kullanıcı, varsayılan değerlerle oluştur
        await _firestore.collection('users').doc(_currentUserId).set({
          'isPremium': false,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActiveAt': FieldValue.serverTimestamp(),
          'totalAnalyses': 0,
        });

        print('User initialized in Firebase');
      } else {
        // Mevcut kullanıcı, son aktiflik zamanını güncelle
        await _firestore.collection('users').doc(_currentUserId).update({
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      }

      // Firebase'den veriyi senkronize et
      await syncUserDataFromFirebase();
    } catch (e) {
      print('Error initializing user in Firebase: $e');
    }
  }

  // Firebase'de premium geçmişini kaydet
  static Future<void> savePremiumPurchaseHistory({
    required String purchaseId,
    required String productId,
    required double amount,
    required String currency,
  }) async {
    try {
      if (_currentUserId == null) return;

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('purchases')
          .doc(purchaseId)
          .set({
        'productId': productId,
        'amount': amount,
        'currency': currency,
        'purchaseDate': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      print('Purchase history saved to Firebase');
    } catch (e) {
      print('Error saving purchase history: $e');
    }
  }

  // Local premium durumu kontrol etme
  static Future<bool> _getPremiumStatusLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
  }

  // Local premium durumu kaydetme
  static Future<void> _setPremiumStatusLocal(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, isPremium);
  }

  // Günlük analiz sayısını kontrol et
  static Future<bool> canMakeAnalysis() async {
    final isPremium = await isPremiumUser();
    if (isPremium) return true; // Premium kullanıcılar sınırsız

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    final lastAnalysisDate = prefs.getString(_lastAnalysisDateKey);
    final dailyCount = prefs.getInt(_dailyAnalysisKey) ?? 0;

    // Eğer tarih değişmişse sayacı sıfırla
    if (lastAnalysisDate != todayString) {
      await prefs.setString(_lastAnalysisDateKey, todayString);
      await prefs.setInt(_dailyAnalysisKey, 0);
      return true;
    }

    return dailyCount < _freeAnalysisLimit;
  }

  // Analiz sayacını artır ve Firebase'e kaydet
  static Future<void> incrementAnalysisCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    final lastAnalysisDate = prefs.getString(_lastAnalysisDateKey);

    if (lastAnalysisDate != todayString) {
      // Yeni gün, sayacı sıfırla
      await prefs.setString(_lastAnalysisDateKey, todayString);
      await prefs.setInt(_dailyAnalysisKey, 1);
    } else {
      // Aynı gün, sayacı artır
      final currentCount = prefs.getInt(_dailyAnalysisKey) ?? 0;
      await prefs.setInt(_dailyAnalysisKey, currentCount + 1);
    }

    // Firebase'de toplam analiz sayısını güncelle
    try {
      if (_currentUserId != null) {
        await _firestore.collection('users').doc(_currentUserId).update({
          'totalAnalyses': FieldValue.increment(1),
          'lastAnalysisAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating analysis count in Firebase: $e');
    }
  }

  // Kalan analiz sayısını al
  static Future<int> getRemainingAnalyses() async {
    final isPremium = await isPremiumUser();
    if (isPremium) return -1; // Sınırsız

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    final lastAnalysisDate = prefs.getString(_lastAnalysisDateKey);
    final dailyCount = prefs.getInt(_dailyAnalysisKey) ?? 0;

    // Eğer tarih değişmişse sayacı sıfırla
    if (lastAnalysisDate != todayString) {
      return _freeAnalysisLimit;
    }

    return _freeAnalysisLimit - dailyCount;
  }

  // Bugünkü analiz sayısını al
  static Future<int> getTodayAnalysisCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    final lastAnalysisDate = prefs.getString(_lastAnalysisDateKey);

    if (lastAnalysisDate != todayString) {
      return 0;
    }

    return prefs.getInt(_dailyAnalysisKey) ?? 0;
  }

  // Analiz geçmişini kaydet
  static Future<void> saveAnalysisToHistory(AnalysisHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = await isPremiumUser();
    final history = await getAnalysisHistory();

    // Yeni analizi başa ekle
    history.insert(0, item);

    // Maksimum sayıyı kontrol et
    final maxItems = isPremium ? _maxHistoryItems : _freeHistoryLimit;
    if (history.length > maxItems) {
      history.removeRange(maxItems, history.length);
    }

    // JSON formatında local'e kaydet
    final jsonHistory = history.map((item) => item.toJson()).toList();
    await prefs.setString(_historyKey, json.encode(jsonHistory));

    // Firebase'e de kaydet
    await _saveAnalysisToFirebase(item);

    // Firebase'deki history'yi de güncelle (limit kontrolü ile)
    await _syncHistoryToFirebase(history);
  }

  // Legacy analiz kaydetme (geriye uyumluluk için)
  static Future<void> saveLegacyAnalysisToHistory({
    required String analysis,
    required String coinName,
    String? coinSymbol,
    double? price,
  }) async {
    final historyItem = AnalysisHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      coinName: coinName,
      coinSymbol: coinSymbol ?? 'UNKNOWN',
      price: price ?? 0.0,
      analysis: analysis,
      technicalData: {},
      timestamp: DateTime.now(),
    );

    await saveAnalysisToHistory(historyItem);
  }

  // Analiz geçmişini al (Firebase'den senkronize ederek)
  static Future<List<AnalysisHistoryItem>> getAnalysisHistory() async {
    try {
      // Önce Firebase'den güncel veriyi al
      if (_currentUserId != null) {
        final firebaseHistory = await _getHistoryFromFirebase();
        if (firebaseHistory.isNotEmpty) {
          // Firebase'den gelen veriyi local'e kaydet
          await _saveHistoryToLocal(firebaseHistory);
          return firebaseHistory;
        }
      }
    } catch (e) {
      print('Error loading history from Firebase: $e');
    }

    // Firebase'den alınamazsa local'den al
    return await _getHistoryFromLocal();
  }

  // Firebase'den history'yi al
  static Future<List<AnalysisHistoryItem>> _getHistoryFromFirebase() async {
    if (_currentUserId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('analyses')
          .orderBy('timestamp', descending: true)
          .get();

      final historyItems = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Firestore doc ID'sini kullan
        return AnalysisHistoryItem.fromJson(data);
      }).toList();

      print('Loaded ${historyItems.length} analyses from Firebase');
      return historyItems;
    } catch (e) {
      print('Error loading history from Firebase: $e');
      return [];
    }
  }

  // Local'den history'yi al
  static Future<List<AnalysisHistoryItem>> _getHistoryFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);

    if (historyJson == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(historyJson);
      return jsonList
          .map((json) => AnalysisHistoryItem.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading analysis history from local: $e');
      return [];
    }
  }

  // History'yi local'e kaydet
  static Future<void> _saveHistoryToLocal(
      List<AnalysisHistoryItem> history) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonHistory = history.map((item) => item.toJson()).toList();
    await prefs.setString(_historyKey, json.encode(jsonHistory));
  }

  // Tek bir analizi Firebase'e kaydet
  static Future<void> _saveAnalysisToFirebase(AnalysisHistoryItem item) async {
    try {
      if (_currentUserId != null) {
        await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('analyses')
            .doc(item.id)
            .set(item.toJson());

        print('Analysis saved to Firebase: ${item.id}');
      }
    } catch (e) {
      print('Error saving analysis to Firebase: $e');
    }
  }

  // Tüm history'yi Firebase'e senkronize et (limit kontrolü ile)
  static Future<void> _syncHistoryToFirebase(
      List<AnalysisHistoryItem> history) async {
    try {
      if (_currentUserId == null) return;

      final isPremium = await isPremiumUser();
      final maxItems = isPremium ? _maxHistoryItems : _freeHistoryLimit;

      // Firebase'den mevcut analiz sayısını al
      final existingQuery = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('analyses')
          .orderBy('timestamp', descending: true)
          .get();

      // Fazla olan analizleri sil
      if (existingQuery.docs.length > maxItems) {
        final toDelete = existingQuery.docs.skip(maxItems);
        final batch = _firestore.batch();

        for (final doc in toDelete) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        print('Deleted ${toDelete.length} old analyses from Firebase');
      }
    } catch (e) {
      print('Error syncing history to Firebase: $e');
    }
  }

  // Firebase'den history'yi tamamen yeniden yükle
  static Future<void> refreshHistoryFromFirebase() async {
    try {
      if (_currentUserId != null) {
        final firebaseHistory = await _getHistoryFromFirebase();
        await _saveHistoryToLocal(firebaseHistory);
        print('History refreshed from Firebase');
      }
    } catch (e) {
      print('Error refreshing history from Firebase: $e');
    }
  }

  // Legacy geçmiş dönüştürme (geriye uyumluluk)
  static Future<List<Map<String, dynamic>>> getLegacyAnalysisHistory() async {
    final history = await getAnalysisHistory();
    return history
        .map((item) => {
              'text': item.analysis,
              'coin': item.coinName,
              'expanded': false,
              'timestamp': item.timestamp.toIso8601String(),
            })
        .toList();
  }

  // Legacy geçmiş kaydetme (geriye uyumluluk)
  static Future<void> saveLegacyAnalysisHistory(
      List<Map<String, dynamic>> legacyHistory) async {
    final prefs = await SharedPreferences.getInstance();

    // Legacy formatından yeni formata dönüştür
    final newHistory = legacyHistory.map((item) {
      return AnalysisHistoryItem(
        id: (item['timestamp'] as String?) ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        coinName: item['coin'] ?? 'Unknown',
        coinSymbol: 'LEGACY',
        price: 0.0,
        analysis: item['text'] ?? '',
        technicalData: {},
        timestamp: DateTime.tryParse(item['timestamp'] ?? '') ?? DateTime.now(),
      );
    }).toList();

    // Kaydet
    final jsonHistory = newHistory.map((item) => item.toJson()).toList();
    await prefs.setString(_historyKey, json.encode(jsonHistory));
  }

  // Analiz geçmişini temizle (hem local hem Firebase)
  static Future<void> clearAnalysisHistory() async {
    // Local'den temizle
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);

    // Firebase'den de temizle
    await _clearHistoryFromFirebase();
  }

  // Firebase'den history'yi temizle
  static Future<void> _clearHistoryFromFirebase() async {
    try {
      if (_currentUserId == null) return;

      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('analyses')
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('All analyses cleared from Firebase');
    } catch (e) {
      print('Error clearing history from Firebase: $e');
    }
  }

  // Belirli bir analizi sil (hem local hem Firebase)
  static Future<void> deleteAnalysis(String analysisId) async {
    // Local'den sil
    final history = await _getHistoryFromLocal();
    history.removeWhere((item) => item.id == analysisId);
    await _saveHistoryToLocal(history);

    // Firebase'den de sil
    await _deleteAnalysisFromFirebase(analysisId);
  }

  // Firebase'den belirli analizi sil
  static Future<void> _deleteAnalysisFromFirebase(String analysisId) async {
    try {
      if (_currentUserId != null) {
        await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('analyses')
            .doc(analysisId)
            .delete();

        print('Analysis deleted from Firebase: $analysisId');
      }
    } catch (e) {
      print('Error deleting analysis from Firebase: $e');
    }
  }

  // Offline durumda yapılan değişiklikleri Firebase'e senkronize et
  static Future<void> syncOfflineChangesToFirebase() async {
    try {
      if (_currentUserId == null) return;

      // Local history'yi al
      final localHistory = await _getHistoryFromLocal();

      // Firebase'e tek tek kaydet
      final batch = _firestore.batch();
      for (final item in localHistory) {
        final docRef = _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('analyses')
            .doc(item.id);

        batch.set(docRef, item.toJson());
      }

      await batch.commit();
      print('Offline changes synced to Firebase');
    } catch (e) {
      print('Error syncing offline changes: $e');
    }
  }

  // Çakışma durumunda Firebase'i öncelik olarak al
  static Future<void> resolveConflictsWithFirebase() async {
    try {
      if (_currentUserId == null) return;

      // Firebase'den güncel veriyi al
      final firebaseHistory = await _getHistoryFromFirebase();

      // Local'e kaydet (Firebase öncelikli)
      await _saveHistoryToLocal(firebaseHistory);

      print('Conflicts resolved with Firebase data');
    } catch (e) {
      print('Error resolving conflicts: $e');
    }
  }

  // History backup oluştur (JSON export)
  static Future<String> exportHistoryBackup() async {
    try {
      final history = await getAnalysisHistory();
      final backup = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'userId': _currentUserId,
        'analysisCount': history.length,
        'analyses': history.map((item) => item.toJson()).toList(),
      };

      return json.encode(backup);
    } catch (e) {
      print('Error creating backup: $e');
      return '';
    }
  }

  // History backup'ı restore et
  static Future<bool> restoreHistoryBackup(String backupJson) async {
    try {
      final backup = json.decode(backupJson);
      final analyses = backup['analyses'] as List<dynamic>;

      final historyItems =
          analyses.map((json) => AnalysisHistoryItem.fromJson(json)).toList();

      // Local'e kaydet
      await _saveHistoryToLocal(historyItems);

      // Firebase'e de kaydet
      if (_currentUserId != null) {
        final batch = _firestore.batch();
        for (final item in historyItems) {
          final docRef = _firestore
              .collection('users')
              .doc(_currentUserId)
              .collection('analyses')
              .doc(item.id);

          batch.set(docRef, item.toJson());
        }

        await batch.commit();
      }

      print('History backup restored successfully');
      return true;
    } catch (e) {
      print('Error restoring backup: $e');
      return false;
    }
  }

  // Premium upgrade mesajı
  static String getPremiumUpgradeMessage() {
    return "🚀 Upgrade to Premium!\n\n"
        "• Unlimited AI analyses per day\n"
        "• Advanced technical indicators\n"
        "• Analysis history (50 items vs 5)\n"
        "• Priority support\n"
        "• No ads\n\n"
        "Free users: 1 analysis per day";
  }

  // Premium özellikleri mesajı
  static String getPremiumFeaturesMessage() {
    return "✨ Premium Features:\n\n"
        "🔥 Unlimited daily analyses\n"
        "📈 50 analysis history (vs 5)\n"
        "⚡ Priority AI processing\n"
        "🎯 Advanced technical indicators\n"
        "📊 Export analysis reports\n"
        "🚫 Ad-free experience\n"
        "💬 Premium support";
  }

  // Limit aşım mesajı
  static String getLimitExceededMessage() {
    return "📊 Daily Analysis Limit Reached!\n\n"
        "You've used your 1 free analysis for today.\n\n"
        "Upgrade to Premium for:\n"
        "• Unlimited daily analyses\n"
        "• Extended history (50 vs 5)\n"
        "• Advanced features\n\n"
        "Free limit resets at midnight.";
  }
}
