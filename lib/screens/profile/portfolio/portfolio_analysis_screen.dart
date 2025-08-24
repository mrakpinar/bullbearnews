import 'package:bullbearnews/models/coin_analysis_result.dart';
import 'package:bullbearnews/widgets/analysis/portfolio_analysis/analysis_progress_widget.dart';
import 'package:bullbearnews/widgets/analysis/portfolio_analysis/coin_analysis_card_widget.dart';
import 'package:bullbearnews/widgets/analysis/portfolio_analysis/empty_state_widget.dart';
import 'package:bullbearnews/widgets/analysis/portfolio_analysis/portfolio_analysis_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/crypto_model.dart';
import '../../../models/wallet_model.dart';
import '../../../services/crypto_service.dart';
import '../../../services/analytics_service.dart';
import '../../../models/chart_candle.dart';

class PortfolioAnalysisScreen extends StatefulWidget {
  const PortfolioAnalysisScreen({super.key});

  @override
  State<PortfolioAnalysisScreen> createState() =>
      _PortfolioAnalysisScreenState();
}

class _PortfolioAnalysisScreenState extends State<PortfolioAnalysisScreen>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CryptoService _cryptoService = CryptoService();

  List<WalletItem> _walletItems = [];
  final Map<String, CoinAnalysisResult> _analysisResults = {};
  bool _isLoading = true;
  bool _isAnalyzing = false;
  String _errorMessage = '';
  double _analysisProgress = 0.0;
  String _currentAnalyzingCoin = '';

  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _listAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPortfolioData();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _headerAnimationController, curve: Curves.easeOut),
    );
    _listAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listAnimationController, curve: Curves.easeOut),
    );

    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _listAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadPortfolioData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wallets')
          .get();

      List<WalletItem> allItems = [];
      for (var doc in snapshot.docs) {
        final wallet = Wallet.fromJson(doc.data()).copyWith(id: doc.id);
        allItems.addAll(wallet.items);
      }

      // Remove duplicates by crypto ID
      final Map<String, WalletItem> uniqueItems = {};
      for (var item in allItems) {
        if (uniqueItems.containsKey(item.cryptoId)) {
          // Combine amounts if same crypto exists in multiple wallets
          final existing = uniqueItems[item.cryptoId]!;
          uniqueItems[item.cryptoId] = existing.copyWith(
            amount: existing.amount + item.amount,
          );
        } else {
          uniqueItems[item.cryptoId] = item;
        }
      }

      setState(() {
        _walletItems = uniqueItems.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading portfolio: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _analyzeAllCoins() async {
    if (_walletItems.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _analysisProgress = 0.0;
      _analysisResults.clear();
    });

    try {
      final cryptoData = await _cryptoService.getCryptoData();

      for (int i = 0; i < _walletItems.length; i++) {
        final item = _walletItems[i];
        setState(() {
          _currentAnalyzingCoin = item.cryptoName;
          _analysisProgress = (i / _walletItems.length);
        });

        try {
          final result = await _analyzeSingleCoin(item, cryptoData);
          setState(() {
            _analysisResults[item.cryptoId] = result;
          });
        } catch (e) {
          setState(() {
            _analysisResults[item.cryptoId] = CoinAnalysisResult(
              coinName: item.cryptoName,
              analysis: 'Analysis failed: ${e.toString()}',
              technicalIndicators: {},
              sentiment: 'Error',
              confidence: 0.0,
              isError: true,
            );
          });
        }

        // Add delay to prevent API rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }

      setState(() {
        _analysisProgress = 1.0;
        _currentAnalyzingCoin = 'Complete';
      });

      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      _showSnackbar('Analysis failed: $e', isError: true);
    } finally {
      setState(() {
        _isAnalyzing = false;
        _currentAnalyzingCoin = '';
      });
    }
  }

  Future<CoinAnalysisResult> _analyzeSingleCoin(
      WalletItem item, List<CryptoModel> cryptoData) async {
    try {
      print('=== ANALYZING ${item.cryptoName} ===');

      // Get current crypto data
      final crypto = cryptoData.firstWhere(
        (c) => c.id == item.cryptoId,
        orElse: () =>
            throw Exception('Crypto data not found for ${item.cryptoName}'),
      );

      print('Found crypto data for ${item.cryptoName}');

      // Get chart data for technical analysis
      List<ChartCandle> chartData;
      try {
        chartData = await AnalyticsService.fetchChartData(
          symbol: item.cryptoSymbol,
          interval: '1d',
          limit: 50,
        );
        print('Chart data length: ${chartData.length}');
      } catch (chartError) {
        print('Chart data error for ${item.cryptoName}: $chartError');
        // Fallback with minimal technical indicators
        return CoinAnalysisResult(
          coinName: item.cryptoName,
          analysis:
              'Technical analysis unavailable. Using basic price data only.',
          technicalIndicators: {
            'current_price': crypto.currentPrice,
            'price_change_24h': crypto.priceChangePercentage24h,
            'rsi': 50.0, // Neutral RSI
            'macd': 'neutral', // Neutral MACD
          },
          sentiment:
              crypto.priceChangePercentage24h >= 0 ? 'Bullish' : 'Bearish',
          confidence: 0.3, // Low confidence due to lack of technical data
          isError: false,
        );
      }

      if (chartData.isEmpty) {
        throw Exception('No chart data available for ${item.cryptoName}');
      }

      // Calculate technical indicators with improved error handling
      final indicators =
          AnalyticsService.calculateTechnicalIndicators(chartData);
      print('Technical indicators calculated: ${indicators.keys}');

      // Calculate MACD with better error handling
      final macdData = AnalyticsService.calculateMACD(
          chartData.map((c) => c.close).toList());
      print('MACD data calculated: $macdData');

      // Extract RSI with default value
      final rsi = indicators['rsi'] ?? 50.0;

      // Extract MACD signal with default value
      final macdSignal = macdData['status'] ?? 'neutral';

      print('RSI: $rsi, MACD: $macdSignal');

      // Send analysis request with error handling
      String? analysisText;
      try {
        analysisText = await AnalyticsService.sendAnalysisRequest(
          coinName: item.cryptoName,
          rsi: rsi,
          macd: macdSignal,
          volume: chartData.last.volume,
        );
        print('Analysis received: ${analysisText?.substring(0, 100)}...');
      } catch (analysisError) {
        print('Analysis request error for ${item.cryptoName}: $analysisError');
        analysisText =
            'AI analysis temporarily unavailable. Based on technical indicators: RSI is ${rsi.toStringAsFixed(1)} and MACD is $macdSignal.';
      }

      // Determine sentiment and confidence
      final sentiment =
          _determineSentiment(analysisText ?? '', rsi, macdSignal);
      final confidence = _calculateConfidence(rsi, macdSignal, chartData);

      print('Final result - Sentiment: $sentiment, Confidence: $confidence');

      return CoinAnalysisResult(
        coinName: item.cryptoName,
        analysis: analysisText ?? 'Analysis completed with limited data',
        technicalIndicators: {
          'rsi': rsi,
          'macd': macdSignal,
          'volume': chartData.last.volume,
          'price_change_24h': crypto.priceChangePercentage24h,
          'current_price': crypto.currentPrice,
          ...indicators,
          ...macdData,
        },
        sentiment: sentiment,
        confidence: confidence,
        isError: false,
      );
    } catch (e) {
      print('Single coin analysis error for ${item.cryptoName}: $e');

      // Return error result instead of rethrowing
      return CoinAnalysisResult(
        coinName: item.cryptoName,
        analysis:
            'Analysis failed: ${e.toString()}. This could be due to network issues or insufficient data.',
        technicalIndicators: {},
        sentiment: 'Error',
        confidence: 0.0,
        isError: true,
      );
    }
  }

  String _determineSentiment(String analysis, double rsi, String macd) {
    final lowerAnalysis = analysis.toLowerCase();

    // Check analysis text first
    if (lowerAnalysis.contains('bearish') ||
        lowerAnalysis.contains('sell') ||
        lowerAnalysis.contains('negative') ||
        lowerAnalysis.contains('düşüş') ||
        lowerAnalysis.contains('satış')) {
      return 'Bearish';
    } else if (lowerAnalysis.contains('bullish') ||
        lowerAnalysis.contains('buy') ||
        lowerAnalysis.contains('positive') ||
        lowerAnalysis.contains('yükseliş') ||
        lowerAnalysis.contains('alım')) {
      return 'Bullish';
    }

    // Fallback to technical indicators
    int bullishSignals = 0;
    int bearishSignals = 0;

    // RSI signals
    if (rsi > 70) {
      bearishSignals++; // Overbought
    } else if (rsi < 30) {
      bullishSignals++; // Oversold
    } else if (rsi > 50) {
      bullishSignals++; // Above midline
    } else if (rsi < 50) {
      bearishSignals++; // Below midline
    }

    // MACD signals
    if (macd.toLowerCase().contains('pozitif') ||
        macd.toLowerCase().contains('positive')) {
      bullishSignals++;
    } else if (macd.toLowerCase().contains('negatif') ||
        macd.toLowerCase().contains('negative')) {
      bearishSignals++;
    }

    if (bullishSignals > bearishSignals) {
      return 'Bullish';
    } else if (bearishSignals > bullishSignals) {
      return 'Bearish';
    } else {
      return 'Neutral';
    }
  }

  double _calculateConfidence(
      double rsi, String macd, List<ChartCandle> chartData) {
    double confidence = 0.4; // Base confidence

    try {
      // RSI confidence - stronger signals at extremes
      if (rsi > 80 || rsi < 20) {
        confidence += 0.3; // Very strong RSI signal
      } else if (rsi > 70 || rsi < 30) {
        confidence += 0.2; // Strong RSI signal
      } else if (rsi > 60 || rsi < 40) {
        confidence += 0.1; // Moderate RSI signal
      }

      // MACD confidence
      if (macd.toLowerCase().contains('pozitif') ||
          macd.toLowerCase().contains('pozitive')) {
        confidence += 0.15;
      } else if (macd.toLowerCase().contains('negatif') ||
          macd.toLowerCase().contains('negative')) {
        confidence += 0.15;
      }

      // Volume confidence
      if (chartData.length >= 10) {
        try {
          final recentVolume = chartData.length >= 3
              ? chartData
                      .sublist(chartData.length - 3)
                      .map((c) => c.volume)
                      .reduce((a, b) => a + b) /
                  3
              : chartData.last.volume;

          final avgVolume =
              chartData.map((c) => c.volume).reduce((a, b) => a + b) /
                  chartData.length;

          if (recentVolume > avgVolume * 1.5) {
            confidence += 0.15; // High volume confirmation
          } else if (recentVolume > avgVolume * 1.2) {
            confidence += 0.1; // Moderate volume confirmation
          }
        } catch (volumeError) {
          print('Volume confidence calculation error: $volumeError');
          // Continue without volume-based confidence adjustment
        }
      }

      return confidence.clamp(0.1, 0.95); // Ensure reasonable confidence bounds
    } catch (e) {
      print('Confidence calculation error: $e');
      return 0.4; // Return base confidence on error
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF222831) : const Color(0xFFDFD0B8),
      body: SafeArea(
        child: Column(
          children: [
            PortfolioAnalysisHeaderWidget(
              isDark: isDark,
              analyzeAllCoins: _analyzeAllCoins,
              headerAnimation: _headerAnimation,
              isAnalyzing: _isAnalyzing,
              walletItems: _walletItems,
            ),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(isDark)
                  : _walletItems.isEmpty
                      ? EmptyStateWidget(isDark: isDark)
                      : _buildAnalysisContent(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading portfolio data...',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              fontWeight: FontWeight.w500,
              fontFamily: 'DMSerif',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisContent(bool isDark) {
    return AnimatedBuilder(
      animation: _listAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _listAnimation.value)),
          child: Opacity(
            opacity: _listAnimation.value,
            child: Column(
              children: [
                if (_isAnalyzing)
                  AnalysisProgressWidget(
                    isDark: isDark,
                    analysisProgress: _analysisProgress,
                    currentAnalyzingCoin: _currentAnalyzingCoin,
                  ),
                Expanded(child: _buildCoinsList(isDark)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoinsList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _walletItems.length,
      itemBuilder: (context, index) {
        final item = _walletItems[index];
        final analysis = _analysisResults[item.cryptoId];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: CoinAnalysisCardWidget(
              item: item, analysis: analysis, isDark: isDark),
        );
      },
    );
  }
}
