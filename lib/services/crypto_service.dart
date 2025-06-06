import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/crypto_model.dart';

class CryptoService {
  static const String _cacheKey = 'cachedCryptoData';
  final String baseUrl = 'https://api.coingecko.com/api/v3';
  List<CryptoModel>? _cachedData;
  DateTime? _lastFetchTime;
  bool _isFetching = false;

  // Cache süresi (10 dakika)
  final Duration _cacheDuration = const Duration(minutes: 10);
  // Yeniden deneme aralığı (1 dakika)
  final Duration _retryCooldown = const Duration(minutes: 1);

  Future<List<CryptoModel>> getCryptoData({bool forceRefresh = false}) async {
    // Eğer zaten veri çekiliyorsa ve forceRefresh false ise, mevcut veriyi döndür
    if (_isFetching && !forceRefresh && _cachedData != null) {
      return _cachedData!;
    }

    // Önbellek kontrolü
    if (!forceRefresh && _shouldUseCache()) {
      return _cachedData!;
    }

    _isFetching = true;
    try {
      final newData = await _fetchFromApi();
      await _saveToCache(newData);
      return newData;
    } catch (e) {
      final cached = await _getFromLocalCache();
      if (cached != null) {
        return cached;
      }
      rethrow;
    } finally {
      _isFetching = false;
    }
  }

  bool _shouldUseCache() {
    return _cachedData != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  Future<List<CryptoModel>> _fetchFromApi() async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1'),
      headers: {'Accept': 'application/json', 'User-Agent': 'BullBearNews/1.0'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => CryptoModel.fromJson(item)).toList();
    } else if (response.statusCode == 429) {
      throw Exception('API request limit exceeded. Please try again later.');
    } else {
      throw Exception(
          'Failed to load data. Status code: ${response.statusCode}');
    }
  }

  Future<void> _saveToCache(List<CryptoModel> data) async {
    _cachedData = data;
    _lastFetchTime = DateTime.now();

    // Local storage'a da kaydet
    final prefs = await SharedPreferences.getInstance();
    final jsonData = data.map((e) => e.toJson()).toList();
    await prefs.setString(_cacheKey, jsonEncode(jsonData));
    await prefs.setString(
        '${_cacheKey}_time', _lastFetchTime!.toIso8601String());
  }

  Future<List<CryptoModel>?> _getFromLocalCache() async {
    if (_cachedData != null) return _cachedData;

    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKey);
    final cachedTime = prefs.getString('${_cacheKey}_time');

    if (cachedData != null && cachedTime != null) {
      try {
        final data = jsonDecode(cachedData) as List;
        _cachedData = data.map((item) => CryptoModel.fromJson(item)).toList();
        _lastFetchTime = DateTime.parse(cachedTime);
        return _cachedData;
      } catch (e) {
        await prefs.remove(_cacheKey);
        await prefs.remove('${_cacheKey}_time');
      }
    }
    return null;
  }
}
