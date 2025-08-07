// services/premium_analysis_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
      technicalData: Map<String, dynamic>.from(json['technicalData']),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class PremiumAnalysisService {
  static const String _historyKey = 'analysis_history';
  static const String _premiumKey = 'is_premium_user';
  static const int _maxHistoryItems = 50; // Premium kullanıcılar için 50 analiz
  static const int _freeAnalysisLimit =
      3; // Ücretsiz kullanıcılar için günlük 3 analiz

  // Premium durumunu kontrol et
  static Future<bool> isPremiumUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? true;
  }

  // Premium durumunu ayarla (test için)
  static Future<void> setPremiumStatus(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, isPremium);
  }

  // Günlük analiz limitini kontrol et
  static Future<bool> canMakeAnalysis() async {
    final isPremium = await isPremiumUser();
    if (isPremium) return true; // Premium kullanıcılar sınırsız

    final history = await getAnalysisHistory();
    final today = DateTime.now();
    final todayAnalyses = history.where((item) {
      return item.timestamp.year == today.year &&
          item.timestamp.month == today.month &&
          item.timestamp.day == today.day;
    }).length;

    return todayAnalyses < _freeAnalysisLimit;
  }

  // Kalan analiz sayısını al
  static Future<int> getRemainingAnalyses() async {
    final isPremium = await isPremiumUser();
    if (isPremium) return -1; // Sınırsız

    final history = await getAnalysisHistory();
    final today = DateTime.now();
    final todayAnalyses = history.where((item) {
      return item.timestamp.year == today.year &&
          item.timestamp.month == today.month &&
          item.timestamp.day == today.day;
    }).length;

    return _freeAnalysisLimit - todayAnalyses;
  }

  // Analiz geçmişini kaydet
  static Future<void> saveAnalysisToHistory(AnalysisHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getAnalysisHistory();

    // Yeni analizi başa ekle
    history.insert(0, item);

    // Maksimum sayıyı aşarsa eski analizleri sil
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }

    // JSON formatında kaydet
    final jsonHistory = history.map((item) => item.toJson()).toList();
    await prefs.setString(_historyKey, json.encode(jsonHistory));
  }

  // Analiz geçmişini al
  static Future<List<AnalysisHistoryItem>> getAnalysisHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);

    if (historyJson == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(historyJson);
      return jsonList
          .map((json) => AnalysisHistoryItem.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading analysis history: $e');
      return [];
    }
  }

  // Analiz geçmişini temizle
  static Future<void> clearAnalysisHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // Belirli bir analizi sil
  static Future<void> deleteAnalysis(String analysisId) async {
    final history = await getAnalysisHistory();
    history.removeWhere((item) => item.id == analysisId);

    final prefs = await SharedPreferences.getInstance();
    final jsonHistory = history.map((item) => item.toJson()).toList();
    await prefs.setString(_historyKey, json.encode(jsonHistory));
  }

  // Premium upgrade mesajı
  static String getPremiumUpgradeMessage() {
    return "🚀 Upgrade to Premium!\n\n"
        "• Unlimited AI analyses\n"
        "• Advanced technical indicators\n"
        "• Analysis history (50 items)\n"
        "• Priority support\n\n"
        "Free users: 3 analyses per day";
  }
}
