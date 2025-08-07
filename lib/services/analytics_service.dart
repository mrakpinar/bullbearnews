import 'package:bullbearnews/models/chart_candle.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static const String SERVER_IP = '192.168.1.102';
  static const int SERVER_PORT = 7860;

  // Detaylı network testi
  static Future<Map<String, dynamic>> detailedNetworkTest() async {
    final results = <String, dynamic>{};

    // 1. Ping testi (HTTP GET ile)
    try {
      print('=== PING TEST ===');
      final response = await http
          .get(
            Uri.parse('http://$SERVER_IP:$SERVER_PORT/'),
          )
          .timeout(const Duration(seconds: 5));

      results['ping'] = {
        'success': true,
        'status': response.statusCode,
        'message': 'Server reachable'
      };
      print('Ping başarılı: ${response.statusCode}');
    } catch (e) {
      results['ping'] = {
        'success': false,
        'error': e.toString(),
        'message': 'Server not reachable'
      };
      print('Ping hatası: $e');
    }

    // 2. Analyze endpoint testi
    try {
      print('=== ANALYZE ENDPOINT TEST ===');
      final response = await http
          .post(
            Uri.parse('http://$SERVER_IP:$SERVER_PORT/analyze'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'coin_name': 'TEST',
              'rsi': 50.0,
              'macd': 'pozitif',
              'volume': 1000000.0,
            }),
          )
          .timeout(const Duration(seconds: 10));

      results['analyze_endpoint'] = {
        'success': response.statusCode == 200,
        'status': response.statusCode,
        'response': response.body,
        'message':
            'Analyze endpoint ${response.statusCode == 200 ? 'working' : 'failed'}'
      };
      print('Analyze endpoint test: ${response.statusCode}');
      print('Response: ${response.body}');
    } catch (e) {
      results['analyze_endpoint'] = {
        'success': false,
        'error': e.toString(),
        'message': 'Analyze endpoint failed'
      };
      print('Analyze endpoint hatası: $e');
    }

    // 3. Chart data endpoint testi
    try {
      print('=== CHART DATA ENDPOINT TEST ===');
      final response = await http
          .get(
            Uri.parse(
                'http://$SERVER_IP:$SERVER_PORT/chart_data?symbol=BTC&interval=1d'),
          )
          .timeout(const Duration(seconds: 10));

      results['chart_endpoint'] = {
        'success': response.statusCode == 200,
        'status': response.statusCode,
        'response': response.body.length > 100
            ? '${response.body.substring(0, 100)}...'
            : response.body,
        'message':
            'Chart endpoint ${response.statusCode == 200 ? 'working' : 'failed'}'
      };
      print('Chart endpoint test: ${response.statusCode}');
    } catch (e) {
      results['chart_endpoint'] = {
        'success': false,
        'error': e.toString(),
        'message': 'Chart endpoint failed'
      };
      print('Chart endpoint hatası: $e');
    }

    return results;
  }

  // Geliştirilmiş sendAnalysisRequest
  static Future<String?> sendAnalysisRequest({
    required String coinName,
    required double rsi,
    required String macd,
    required double volume,
  }) async {
    print('=== ANALYTICS SERVICE DEBUG ===');
    print('Target Server: http://$SERVER_IP:$SERVER_PORT/analyze');

    final requestBody = {
      'coin_name': coinName,
      'rsi': rsi,
      'macd': macd,
      'volume': volume,
    };

    print('Request Body: ${jsonEncode(requestBody)}');

    try {
      print('HTTP POST isteği gönderiliyor...');

      final response = await http
          .post(
            Uri.parse('http://$SERVER_IP:$SERVER_PORT/analyze'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Connection': 'keep-alive',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('Response Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          print('Decoded Data: $data');

          if (data != null && data['analysis'] != null) {
            return data['analysis'];
          } else {
            print('Analysis field is null or empty in response');
            return "Analiz sonucu bulunamadı - Response: ${response.body}";
          }
        } catch (jsonError) {
          print('JSON decode hatası: $jsonError');
          return "JSON parse hatası: ${response.body}";
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Error Body: ${response.body}');
        return "Sunucu hatası (${response.statusCode}): ${response.body}";
      }
    } catch (e) {
      print('Request Exception: $e');

      if (e.toString().contains('TimeoutException')) {
        return "Bağlantı zaman aşımı: Sunucu $SERVER_IP:$SERVER_PORT adresinde yanıt vermiyor";
      } else if (e.toString().contains('SocketException')) {
        return "Network hatası: Sunucuya erişilemiyor ($SERVER_IP:$SERVER_PORT)";
      } else {
        return "Bağlantı hatası: $e";
      }
    }
  }

  // Geliştirilmiş grafik verisi çekme - Candlestick (OHLC) formatında
  static Future<List<ChartCandle>> fetchChartData({
    required String symbol,
    required String
        interval, // '1m', '5m', '15m', '30m', '1h', '4h', '1d', '1w'
    int limit = 100,
  }) async {
    print('=== CHART DATA FETCH ===');
    print('Symbol: $symbol, Interval: $interval, Limit: $limit');

    try {
      final uri = Uri.parse('http://$SERVER_IP:$SERVER_PORT/chart_data')
          .replace(queryParameters: {
        'symbol': symbol,
        'interval': interval,
        'limit': limit.toString(),
      });

      print('Request URI: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));

      print('Chart Data Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> rawData =
            jsonDecode(utf8.decode(response.bodyBytes));
        print('Raw data length: ${rawData.length}');

        if (rawData.isEmpty) {
          throw Exception('No chart data available for $symbol');
        }

        final candles = rawData
            .map((e) => ChartCandle.fromMap(e as Map<String, dynamic>))
            .toList();

        // Timestamp'e göre sırala (eskiden yeniye)
        candles.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        print('Successfully parsed ${candles.length} candles');
        return candles;
      } else {
        print('Chart Data Error Body: ${response.body}');
        throw Exception(
            'Grafik verisi alınamadı (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('Chart data fetch error: $e');
      rethrow;
    }
  }

  // Popüler coin listesi
  static Future<List<String>> getPopularCoins() async {
    try {
      final response = await http
          .get(Uri.parse('http://$SERVER_IP:$SERVER_PORT/popular_coins'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      } else {
        // Fallback - varsayılan coin listesi
        return ['BTC', 'ETH', 'BNB', 'ADA', 'DOT', 'SOL', 'MATIC', 'AVAX'];
      }
    } catch (e) {
      print('Popular coins fetch error: $e');
      // Fallback - varsayılan coin listesi
      return ['BTC', 'ETH', 'BNB', 'ADA', 'DOT', 'SOL', 'MATIC', 'AVAX'];
    }
  }

  // Gerçek zamanlı fiyat bilgisi
  static Future<Map<String, dynamic>?> getCurrentPrice(String symbol) async {
    try {
      final uri = Uri.parse('http://$SERVER_IP:$SERVER_PORT/current_price')
          .replace(queryParameters: {'symbol': symbol});

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Current price fetch error: $e');
    }
    return null;
  }

  // Analiz geçmişini yükleme
  static Future<List<Map<String, dynamic>>> loadAnalysisHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('analysis_history');
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((e) => {
                'text': e['text'],
                'coin': e['coin'] ?? 'Unknown',
                'expanded': e['expanded'] ?? false,
                'timestamp': e['timestamp'] ?? DateTime.now().toIso8601String(),
              })
          .toList();
    }
    return [];
  }

  // Analiz geçmişini kaydetme
  static Future<void> saveAnalysisHistory(
      List<Map<String, dynamic>> history) async {
    final prefs = await SharedPreferences.getInstance();

    // Timestamp ekle eğer yoksa
    final updatedHistory = history.map((item) {
      if (!item.containsKey('timestamp')) {
        item['timestamp'] = DateTime.now().toIso8601String();
      }
      return item;
    }).toList();

    final jsonString = jsonEncode(updatedHistory);
    await prefs.setString('analysis_history', jsonString);
  }

  // RSI durumunu belirleme
  static String getRSIStatus(double rsi) {
    if (rsi >= 70) return 'Aşırı Alım';
    if (rsi <= 30) return 'Aşırı Satım';
    return 'Nötr';
  }

  // RSI rengini belirleme
  static Color getRSIColor(double rsi) {
    if (rsi >= 70) return Colors.red;
    if (rsi <= 30) return Colors.green;
    return Colors.orange;
  }

  // MACD durumunu belirleme
  static String getMACDStatus(String macd) {
    final lowerMacd = macd.toLowerCase();
    if (lowerMacd.contains('pozitif') || lowerMacd.contains('positive')) {
      return 'Pozitif';
    } else if (lowerMacd.contains('negatif') ||
        lowerMacd.contains('negative')) {
      return 'Negatif';
    }
    return 'Nötr';
  }

  // MACD rengini belirleme
  static Color getMACDColor(String macd) {
    final lowerMacd = macd.toLowerCase();
    if (lowerMacd.contains('pozitif') || lowerMacd.contains('positive')) {
      return Colors.green;
    } else if (lowerMacd.contains('negatif') ||
        lowerMacd.contains('negative')) {
      return Colors.red;
    }
    return Colors.orange;
  }

  // Teknik göstergeleri hesaplama
  static Map<String, dynamic> calculateTechnicalIndicators(
      List<ChartCandle> candles) {
    if (candles.isEmpty) return {};

    final closes = candles.map((c) => c.close).toList();
    final volumes = candles.map((c) => c.volume).toList();

    return {
      'rsi': calculateRSI(closes, 14),
      'sma_20': calculateSMA(closes, 20),
      'sma_50': calculateSMA(closes, 50),
      'volume_avg': volumes.isNotEmpty
          ? volumes.reduce((a, b) => a + b) / volumes.length
          : 0,
      'price_change_24h': closes.length >= 2
          ? ((closes.last - closes[closes.length - 2]) /
                  closes[closes.length - 2]) *
              100
          : 0,
    };
  }

// Add this to AnalyticsService class
  static Map<String, dynamic> calculateMACD(List<double> prices) {
    if (prices.length < 26) return {};

    final ema12 = calculateEMA(prices, 12);
    final ema26 = calculateEMA(prices, 26);

    // Calculate MACD line (12-day EMA - 26-day EMA)
    final macdLine = List<double>.generate(
        prices.length, (i) => i >= 25 ? ema12[i] - ema26[i] : 0);

    // Calculate signal line (9-day EMA of MACD line)
    final signalLine = calculateEMA(macdLine.sublist(25), 9);

    // Calculate MACD histogram (MACD line - signal line)
    final histogram = List<double>.generate(
        signalLine.length, (i) => macdLine[25 + i] - signalLine[i]);

    return {
      'macd': macdLine.last,
      'signal': signalLine.last,
      'histogram': histogram.last,
    };
  }

  static List<double> calculateEMA(List<double> prices, int period) {
    final List<double> ema = [];
    final double multiplier = 2 / (period + 1);

    // Simple MA for first value
    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += prices[i];
    }
    ema.add(sum / period);

    // EMA for subsequent values
    for (int i = period; i < prices.length; i++) {
      ema.add((prices[i] - ema.last) * multiplier + ema.last);
    }

    return ema;
  }

  // RSI hesaplama
  static double calculateRSI(List<double> prices, int period) {
    if (prices.length < period + 1) return 50.0;

    List<double> gains = [];
    List<double> losses = [];

    for (int i = 1; i < prices.length; i++) {
      double change = prices[i] - prices[i - 1];
      gains.add(change > 0 ? change : 0);
      losses.add(change < 0 ? -change : 0);
    }

    double avgGain = gains.take(period).reduce((a, b) => a + b) / period;
    double avgLoss = losses.take(period).reduce((a, b) => a + b) / period;

    if (avgLoss == 0) return 100.0;

    double rs = avgGain / avgLoss;
    return 100 - (100 / (1 + rs));
  }

  // SMA hesaplama
  static double calculateSMA(List<double> prices, int period) {
    if (prices.length < period) return 0.0;

    double sum = prices.sublist(prices.length - period).reduce((a, b) => a + b);
    return sum / period;
  }
}
