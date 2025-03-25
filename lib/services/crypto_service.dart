import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/crypto_model.dart';

class CryptoService {
  final String baseUrl = 'https://api.coingecko.com/api/v3';
  List<CryptoModel>? _cachedData;
  DateTime? _lastFetchTime;

  // Önbellek süresi (5 dakika)
  final Duration _cacheDuration = const Duration(minutes: 5);

  Future<List<CryptoModel>> getCryptoData({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedData != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      print('Önbellekten kripto verisi alınıyor...');
      return _cachedData!;
    }

    try {
      print('API\'den kripto verisi alınıyor...');
      final response = await http.get(
        Uri.parse(
            '$baseUrl/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1'),
        headers: {
          'Accept': 'application/json',
          'User-Agent':
              'BullBearNews/1.0', // Uygulamanızın adını ve sürümünü belirtin
        },
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        _cachedData = data.map((item) => CryptoModel.fromJson(item)).toList();
        _lastFetchTime = DateTime.now();
        return _cachedData!;
      } else if (response.statusCode == 429) {
        // Rate limit hatası özel olarak ele alınıyor
        if (_cachedData != null) {
          print('Rate limit exceeded, returning data from cache...');
          return _cachedData!;
        }
        throw Exception('API request limit exceeded. Please try again later.');
      } else {
        throw Exception(
            'Data could not be received. Error code: ${response.statusCode}');
      }
    } catch (e) {
      // Bir hata oluştuğunda önbellekte veri varsa onu döndür
      if (_cachedData != null) {
        print('Error occurred, returning data from cache: $e');
        return _cachedData!;
      }
      throw Exception('An error occurred while retrieving data: $e');
    }
  }
}
