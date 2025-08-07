// services/auto_analysis_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class AutoAnalysisService {
  static const String _baseUrl =
      'http://192.168.1.102:7860'; // Android emulator için
  // static const String _baseUrl = 'http://localhost:8000'; // iOS simulator için

  static Future<Map<String, dynamic>?> performCompleteAnalysis({
    required String symbol,
    required String coinName,
    required double currentPrice,
  }) async {
    try {
      // 1. Fiyat verilerini al
      final priceData = await _getPriceData(symbol);
      if (priceData == null) return null;

      // 2. Teknik göstergeleri hesapla
      final technicalData =
          _calculateTechnicalIndicators(priceData, currentPrice);

      // 3. AI analizi için prompt hazırla
      final prompt =
          _buildAnalysisPrompt(coinName, symbol, currentPrice, technicalData);

      // 4. AI analizini al
      final aiAnalysis = await _getAIAnalysis(prompt);
      if (aiAnalysis == null) return null;

      return {
        'analysis': aiAnalysis,
        'technicalData': technicalData,
        'priceData': priceData,
      };
    } catch (e) {
      print('AutoAnalysisService error: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> _getPriceData(
      String symbol) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/chart_data?symbol=${symbol.toUpperCase()}&interval=1d'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      print('Price data error: $e');
      return null;
    }
  }

  static Map<String, dynamic> _calculateTechnicalIndicators(
    List<Map<String, dynamic>> priceData,
    double currentPrice,
  ) {
    if (priceData.length < 20) {
      return {
        'rsi': 'Insufficient data',
        'macd': 'Insufficient data',
        'bollingerBands': 'Insufficient data',
        'volumeTrend': 'Insufficient data',
        'movingAverages': 'Insufficient data',
        'supportResistance': 'Insufficient data',
      };
    }

    // Fiyat ve hacim listelerini double olarak cast et
    final prices =
        priceData.map((d) => (d['close'] as num).toDouble()).toList();
    final volumes =
        priceData.map((d) => (d['volume'] as num).toDouble()).toList();
    final highs = priceData.map((d) => (d['high'] as num).toDouble()).toList();
    final lows = priceData.map((d) => (d['low'] as num).toDouble()).toList();

    return {
      'rsi': _calculateRSI(prices).toStringAsFixed(1),
      'macd': _calculateMACD(prices),
      'bollingerBands': _calculateBollingerBands(prices, currentPrice),
      'volumeTrend': _calculateVolumeTrend(volumes),
      'movingAverages': _calculateMovingAverages(prices, currentPrice),
      'supportResistance':
          _calculateSupportResistance(highs, lows, currentPrice),
    };
  }

  static double _calculateRSI(List<double> prices, {int period = 14}) {
    if (prices.length < period + 1) return 50.0;

    double avgGain = 0;
    double avgLoss = 0;

    // İlk periyot için ortalama kazanç ve kayıp hesapla
    for (int i = 1; i <= period; i++) {
      double change = prices[i] - prices[i - 1];
      if (change > 0) {
        avgGain += change;
      } else {
        avgLoss += change.abs();
      }
    }
    avgGain /= period;
    avgLoss /= period;

    // Son değerler için RSI hesapla
    for (int i = period + 1; i < prices.length; i++) {
      double change = prices[i] - prices[i - 1];
      if (change > 0) {
        avgGain = (avgGain * (period - 1) + change) / period;
        avgLoss = (avgLoss * (period - 1)) / period;
      } else {
        avgGain = (avgGain * (period - 1)) / period;
        avgLoss = (avgLoss * (period - 1) + change.abs()) / period;
      }
    }

    if (avgLoss == 0) return 100;
    double rs = avgGain / avgLoss;
    return 100 - (100 / (1 + rs));
  }

  static String _calculateMACD(List<double> prices) {
    if (prices.length < 26) return 'Neutral';

    final ema12 = _calculateEMA(prices, 12);
    final ema26 = _calculateEMA(prices, 26);
    final macdLine = ema12 - ema26;

    if (macdLine > 0) {
      return 'Bullish';
    } else if (macdLine < 0) {
      return 'Bearish';
    }
    return 'Neutral';
  }

  static double _calculateEMA(List<double> prices, int period) {
    if (prices.isEmpty) return 0;

    double multiplier = 2 / (period + 1);
    double ema = prices[0];

    for (int i = 1; i < prices.length; i++) {
      ema = (prices[i] - ema) * multiplier + ema;
    }
    return ema;
  }

  static String _calculateBollingerBands(
      List<double> prices, double currentPrice) {
    if (prices.length < 20) return 'Neutral';

    final sma20 =
        prices.sublist(prices.length - 20).reduce((a, b) => a + b) / 20;

    double variance = 0;
    for (int i = prices.length - 20; i < prices.length; i++) {
      variance += pow(prices[i] - sma20, 2);
    }
    double stdDev = sqrt(variance / 20);

    double upperBand = sma20 + (2 * stdDev);
    double lowerBand = sma20 - (2 * stdDev);

    if (currentPrice > upperBand) {
      return 'Overbought';
    } else if (currentPrice < lowerBand) {
      return 'Oversold';
    }
    return 'Normal Range';
  }

  static String _calculateVolumeTrend(List<double> volumes) {
    if (volumes.length < 10) return 'Neutral';

    final recentAvg =
        volumes.sublist(volumes.length - 5).reduce((a, b) => a + b) / 5;
    final previousAvg = volumes
            .sublist(volumes.length - 10, volumes.length - 5)
            .reduce((a, b) => a + b) /
        5;

    if (recentAvg > previousAvg * 1.2) {
      return 'Increasing';
    } else if (recentAvg < previousAvg * 0.8) {
      return 'Decreasing';
    }
    return 'Stable';
  }

  static String _calculateMovingAverages(
      List<double> prices, double currentPrice) {
    if (prices.length < 50) return 'Neutral';

    final sma20 =
        prices.sublist(prices.length - 20).reduce((a, b) => a + b) / 20;
    final sma50 =
        prices.sublist(prices.length - 50).reduce((a, b) => a + b) / 50;

    if (currentPrice > sma20 && sma20 > sma50) {
      return 'Strong Bullish';
    } else if (currentPrice > sma20 && sma20 < sma50) {
      return 'Weak Bullish';
    } else if (currentPrice < sma20 && sma20 > sma50) {
      return 'Weak Bearish';
    } else {
      return 'Strong Bearish';
    }
  }

  static String _calculateSupportResistance(
      List<double> highs, List<double> lows, double currentPrice) {
    if (highs.length < 20) return 'Neutral';

    final recentHighs = highs.sublist(highs.length - 20);
    final recentLows = lows.sublist(lows.length - 20);

    final resistance = recentHighs.reduce(max);
    final support = recentLows.reduce(min);

    final resistanceDistance =
        ((resistance - currentPrice) / currentPrice * 100).abs();
    final supportDistance =
        ((currentPrice - support) / currentPrice * 100).abs();

    if (resistanceDistance < 3) {
      return 'Near Resistance';
    } else if (supportDistance < 3) {
      return 'Near Support';
    }
    return 'Mid Range';
  }

  static String _buildAnalysisPrompt(String coinName, String symbol,
      double currentPrice, Map<String, dynamic> technicalData) {
    return '''
Perform a comprehensive technical analysis for $coinName ($symbol) at current price \$${currentPrice.toStringAsFixed(2)}.

Technical Indicators:
- RSI: ${technicalData['rsi']}
- MACD: ${technicalData['macd']}
- Bollinger Bands: ${technicalData['bollingerBands']}
- Volume Trend: ${technicalData['volumeTrend']}
- Moving Averages: ${technicalData['movingAverages']}
- Support/Resistance: ${technicalData['supportResistance']}

Please provide:
1. Overall market sentiment (Bullish/Bearish/Neutral)
2. Short-term outlook (1-7 days)
3. Key support and resistance levels
4. Risk assessment
5. Trading recommendation

Keep the analysis concise, professional, and actionable. Limit to 150-200 words.
''';
  }

  static Future<String?> _getAIAnalysis(String prompt) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/analyze'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'coin_name': 'Auto Analysis',
              'rsi': 50.0,
              'macd': 'neutral',
              'volume': 1000000.0,
              'custom_prompt': prompt,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['analysis'];
      }
      return null;
    } catch (e) {
      print('AI Analysis error: $e');
      return null;
    }
  }
}
