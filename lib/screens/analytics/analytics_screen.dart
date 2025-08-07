import 'dart:async';

import 'package:bullbearnews/models/crypto_model.dart';
import 'package:bullbearnews/services/analytics_service.dart';
import 'package:bullbearnews/services/crypto_service.dart';
import 'package:bullbearnews/widgets/analysis/analytic_header.dart';
import 'package:bullbearnews/widgets/analysis/analysis_form.dart';
import 'package:flutter/material.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _formAnimationController;
  late AnimationController _historyAnimationController;
  late AnimationController _tabAnimationController;
  late AnimationController _loadingAnimationController;
  late TabController _tabController;

  late Animation<double> _headerAnimation;
  late Animation<double> _formAnimation;
  late Animation<double> _historyAnimation;
  late Animation<double> _tabAnimation;
  late Animation<double> _loadingAnimation;

  final CryptoService _cryptoService = CryptoService();

  double _rsi = 50;
  String _macd = 'pozitif';
  final TextEditingController _volumeController = TextEditingController();
  String? _lastAnalysis;
  List<Map<String, dynamic>> _analysisHistory = [];
  bool _isLoading = false;
  bool _isLoadingCoins = true;

  Timer? _formAnimationDelayTimer;
  Timer? _historyAnimationDelayTimer;
  Timer? _tabAnimationDelayTimer;

  // Coin selection
  List<CryptoModel> _availableCoins = [];
  CryptoModel? _selectedCoin;
  final TextEditingController _coinSearchController = TextEditingController();
  List<CryptoModel> _filteredCoins = [];
  bool _showCoinDropdown = false;

  // Quick selection coins
  final List<String> _quickCoins = ['BTC', 'ETH', 'BNB', 'ADA', 'SOL'];

  bool get _isVolumeValid =>
      double.tryParse(_volumeController.text) != null &&
      double.parse(_volumeController.text) > 0;

  bool get _canAnalyze =>
      _selectedCoin != null && _isVolumeValid && !_isLoading;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAnimations();
    _loadAnalysisHistory();
    _loadAvailableCoins();
    _setDefaultVolume();
  }

  void _setDefaultVolume() {
    _volumeController.text = '10000000';
  }

  Future<void> _clearHistory() async {
    setState(() {
      _analysisHistory.clear();
    });
    await AnalyticsService.saveAnalysisHistory(_analysisHistory);
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _historyAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _headerAnimationController, curve: Curves.easeOut),
    );
    _formAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formAnimationController, curve: Curves.easeOut),
    );
    _historyAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _historyAnimationController, curve: Curves.easeOut),
    );
    _tabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tabAnimationController, curve: Curves.easeOut),
    );
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _loadingAnimationController, curve: Curves.easeInOut),
    );

    if (mounted) {
      _headerAnimationController.forward();
      _formAnimationDelayTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) _tabAnimationController.forward();
      });
      _historyAnimationDelayTimer =
          Timer(const Duration(milliseconds: 400), () {
        if (mounted) _formAnimationController.forward();
      });
      Timer(const Duration(milliseconds: 500), () {
        if (mounted) _historyAnimationController.forward();
      });
    }
  }

  void _deleteSingleItem(int index) {
    setState(() {
      _analysisHistory.removeAt(index);
    });
  }

  Future<void> _loadAvailableCoins() async {
    try {
      final coins = await _cryptoService.getCryptoData();
      if (!mounted) return;
      setState(() {
        _availableCoins = coins.take(100).toList();
        _filteredCoins = _availableCoins;
        _isLoadingCoins = false;

        // Bitcoin'i varsayılan olarak seç
        _selectedCoin = _availableCoins.firstWhere(
          (coin) => coin.symbol.toLowerCase() == 'btc',
          orElse: () => _availableCoins.first,
        );
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingCoins = false;
      });

      if (mounted) {
        _showErrorSnackBar('Failed to load coins: $e');
      }
    }
  }

  void _filterCoins(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCoins = _availableCoins;
      } else {
        _filteredCoins = _availableCoins.where((coin) {
          return coin.name.toLowerCase().contains(query.toLowerCase()) ||
              coin.symbol.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _onCoinSelected(CryptoModel coin) {
    setState(() {
      _selectedCoin = coin;
      _showCoinDropdown = false;
      _coinSearchController.clear();
      _filteredCoins = _availableCoins;
    });
  }

  void _onQuickCoinSelected(String symbol) {
    final coin = _availableCoins.firstWhere(
      (coin) => coin.symbol.toLowerCase() == symbol.toLowerCase(),
      orElse: () => _availableCoins.first,
    );
    _onCoinSelected(coin);
  }

  @override
  void dispose() {
    _formAnimationDelayTimer?.cancel();
    _historyAnimationDelayTimer?.cancel();
    _tabAnimationDelayTimer?.cancel();

    if (mounted) {
      _headerAnimationController.dispose();
      _formAnimationController.dispose();
      _historyAnimationController.dispose();
      _tabAnimationController.dispose();
      _loadingAnimationController.dispose();
      _tabController.dispose();
    }
    _volumeController.dispose();
    _coinSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalysisHistory() async {
    final history = await AnalyticsService.loadAnalysisHistory();
    if (mounted) {
      setState(() => _analysisHistory = history);
    }
  }

  Future<void> _saveAnalysisHistory() async {
    await AnalyticsService.saveAnalysisHistory(_analysisHistory);
  }

  Future<void> _addAnalysis(String text, String coinName) async {
    setState(() {
      _analysisHistory.insert(0, {
        'text': text,
        'coin': coinName,
        'expanded': false,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      if (_analysisHistory.length > 10) {
        _analysisHistory.removeLast();
      }
    });
    await _saveAnalysisHistory();
  }

  Future<String?> _sendAnalysisRequest() async {
    print('_sendAnalysisRequest başlatıldı');
    print('Seçilen coin: ${_selectedCoin?.name}');
    print('RSI: $_rsi');
    print('MACD: $_macd');
    print('Volume: ${_volumeController.text}');

    setState(() => _isLoading = true);
    _loadingAnimationController.forward();

    try {
      final result = await AnalyticsService.sendAnalysisRequest(
        coinName: _selectedCoin!.name,
        rsi: _rsi,
        macd: _macd,
        volume: double.parse(_volumeController.text),
      );

      if (result != null && mounted) {
        setState(() => _lastAnalysis = result);
        await _addAnalysis(result, _selectedCoin!.name);

        if (mounted) {
          _showSuccessSnackBar('Analysis completed successfully!');
          // Otomatik olarak History tab'ına geç
          _tabController.animateTo(1);
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('Analysis failed. Please try again.');
        }
      }
    } catch (e) {
      print('Hata: $e');
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _loadingAnimationController.reverse();
      }
    }
    return null;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF222831) : const Color(0xFFDFD0B8),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark),
                _buildTabBar(isDark),
                Expanded(
                  child: _buildTabBarView(isDark),
                ),
              ],
            ),
          ),
          // Full screen loading overlay
          if (_isLoading) _buildLoadingOverlay(isDark),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(bool isDark) {
    return AnimatedBuilder(
      animation: _loadingAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _loadingAnimation.value,
          child: Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF393E46) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF948979),
                            ),
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF948979).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: const Color(0xFF948979),
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Analyzing ${_selectedCoin?.name ?? "Cryptocurrency"}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                        fontFamily: 'DMSerif',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI is processing your technical indicators...',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFF948979)
                            : const Color(0xFF393E46),
                        fontFamily: 'DMSerif',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF948979).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '🔍 RSI: ${_rsi.round()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF948979),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '📈 MACD: $_macd',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF948979),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return AnalyticHeader(
      animation: _headerAnimation,
      onRefresh: () {
        _loadAnalysisHistory();
        _loadAvailableCoins();
      },
      isDark: isDark,
    );
  }

  Widget _buildTabBar(bool isDark) {
    return AnimatedBuilder(
      animation: _tabAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _tabAnimation.value)),
          child: Opacity(
            opacity: _tabAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF393E46).withOpacity(0.8)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF393E46),
                      const Color(0xFF948979),
                    ],
                  ),
                ),
                labelColor: Colors.white,
                unselectedLabelColor:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  fontFamily: 'DMSerif',
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  fontFamily: 'DMSerif',
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text('Analysis'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text('History'),
                        if (_analysisHistory.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints:
                                BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '${_analysisHistory.length}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBarView(bool isDark) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAnalysisTab(isDark),
        _buildHistoryTab(isDark),
      ],
    );
  }

  Widget _buildAnalysisTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Quick coin selection
          _buildQuickCoinSelection(isDark),

          const SizedBox(height: 20),

          // Analiz formu
          AnalysisForm(
            animation: _formAnimation,
            isDark: isDark,
            rsi: _rsi,
            macd: _macd,
            volumeController: _volumeController,
            isLoading: _isLoading,
            isLoadingCoins: _isLoadingCoins,
            availableCoins: _availableCoins,
            filteredCoins: _filteredCoins,
            selectedCoin: _selectedCoin,
            showCoinDropdown: _showCoinDropdown,
            canAnalyze: _canAnalyze,
            onAnalyze: _sendAnalysisRequest,
            onRSIChanged: (value) {
              setState(() {
                _rsi = value;
              });
            },
            onMACDChanged: (value) {
              setState(() {
                _macd = value;
              });
            },
            onVolumeChanged: (text) {
              setState(() {});
            },
            onCoinSelected: _onCoinSelected,
            onSearchChanged: _filterCoins,
            onToggleDropdown: () {
              setState(() {
                _showCoinDropdown = !_showCoinDropdown;
                if (!_showCoinDropdown) {
                  _coinSearchController.clear();
                  _filteredCoins = _availableCoins;
                }
              });
            },
          ),

          const SizedBox(height: 24),

          // Son analiz sonucu
          if (_lastAnalysis != null) _buildAnalysisCard(_lastAnalysis!, isDark),
        ],
      ),
    );
  }

  Widget _buildQuickCoinSelection(bool isDark) {
    return AnimatedBuilder(
      animation: _formAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _formAnimation.value)),
          child: Opacity(
            opacity: _formAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF393E46).withOpacity(0.5)
                    : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.flash_on,
                        color: const Color(0xFF948979),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Select',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFDFD0B8)
                              : const Color(0xFF222831),
                          fontFamily: 'DMSerif',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickCoins.map((symbol) {
                      final isSelected =
                          _selectedCoin?.symbol.toUpperCase() == symbol;
                      return GestureDetector(
                        onTap: () => _onQuickCoinSelected(symbol),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      const Color(0xFF393E46),
                                      const Color(0xFF948979)
                                    ],
                                  )
                                : null,
                            color: isSelected
                                ? null
                                : (isDark
                                    ? const Color(0xFF222831).withOpacity(0.5)
                                    : const Color(0xFFDFD0B8).withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : const Color(0xFF948979).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            symbol,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? const Color(0xFF948979)
                                      : const Color(0xFF393E46)),
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              fontSize: 14,
                              fontFamily: 'DMSerif',
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _buildDirectHistorySection(isDark),
    );
  }

  // Direkt history section - import yok, tamamen kendi içinde
  Widget _buildDirectHistorySection(bool isDark) {
    return AnimatedBuilder(
      animation: _historyAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _historyAnimation.value)),
          child: Opacity(
            opacity: _historyAnimation.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF393E46),
                            const Color(0xFF948979),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Analysis History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFDFD0B8)
                              : const Color(0xFF222831),
                          fontFamily: 'DMSerif',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_sharp,
                        color: isDark
                            ? const Color(0xFF948979)
                            : const Color(0xFF393E46),
                      ),
                      onPressed: _analysisHistory.isNotEmpty
                          ? () => _clearHistory()
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Content
                _analysisHistory.isEmpty
                    ? _buildEmptyState(isDark)
                    : Column(
                        children: _analysisHistory
                            .asMap()
                            .entries
                            .map<Widget>((entry) {
                          final index = entry.key;
                          final item = entry.value;

                          final text = item['text'] as String;
                          final coinName = item['coin'] as String? ?? 'Unknown';
                          final timestamp = item['timestamp'] as int? ??
                              DateTime.now().millisecondsSinceEpoch;

                          print('\n=== DIRECT HISTORY ITEM $index ===');
                          print('Full text: $text');

                          // DIREKT skorlama burada
                          final style = _calculateDirectStyle(text);

                          print('DIRECT FINAL: ${style['sentiment']}');
                          print('=== END DIRECT ITEM $index ===\n');

                          return _buildHistoryItem(context, isDark, index,
                              coinName, text, timestamp, style);
                        }).toList(),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Direkt skorlama fonksiyonu
  Map<String, dynamic> _calculateDirectStyle(String analysisText) {
    final lower = analysisText.toLowerCase();

    print('📊 DIRECT SCORING START');
    print(
        'Text preview: ${lower.length > 100 ? "${lower.substring(0, 100)}..." : lower}');

    // Önce neutral check
    bool isNeutral = lower.contains('market condition: neutral') ||
        lower.contains('1) market condition: neutral') ||
        lower.contains('neutral zone');

    print('Neutral check: $isNeutral');
    print(
        'Contains "market condition: neutral": ${lower.contains('market condition: neutral')}');

    if (isNeutral) {
      print('🟠 DIRECT: NEUTRAL DETECTED');
      return {
        'color': Colors.orange,
        'icon': Icons.warning_rounded,
        'sentiment': 'NEUTRAL'
      };
    }

    // Skorlama
    int bull = 0, bear = 0, neutral = 0;

    // Bearish
    if (lower.contains('bearish')) bear += 5;
    if (lower.contains('sell')) bear += 4;
    if (lower.contains('negative')) bear += 3;
    if (lower.contains('downtrend')) bear += 3;
    if (lower.contains('overbought')) bear += 2;
    if (lower.contains('caution')) bear += 1;

    // Bullish
    if (lower.contains('bullish')) {
      if (lower.contains('slight bullish') || lower.contains('bullish bias')) {
        bull += 2;
      } else {
        bull += 5;
      }
    }
    if (lower.contains('buy')) bull += 4;
    if (lower.contains('positive')) bull += 3;
    if (lower.contains('uptrend')) bull += 3;
    if (lower.contains('support')) bull += 2;
    if (lower.contains('oversold')) bull += 2;

    // Neutral
    if (lower.contains('neutral')) neutral += 6;
    if (lower.contains('sideways')) neutral += 4;
    if (lower.contains('range')) neutral += 3;
    if (lower.contains('hold')) neutral += 3;
    if (lower.contains('wait')) neutral += 2;
    if (lower.contains('lack of strong')) neutral += 2;

    print('📊 SCORES: Bull=$bull, Bear=$bear, Neutral=$neutral');

    if (neutral >= bull && neutral >= bear && neutral > 0) {
      print('🟠 DIRECT: NEUTRAL WINS');
      return {
        'color': Colors.orange,
        'icon': Icons.warning_rounded,
        'sentiment': 'NEUTRAL'
      };
    } else if (bear > bull && bear > neutral) {
      print('🔴 DIRECT: BEARISH WINS');
      return {
        'color': Colors.red,
        'icon': Icons.trending_down_rounded,
        'sentiment': 'BEARISH'
      };
    } else if (bull > bear && bull > neutral) {
      print('🟢 DIRECT: BULLISH WINS');
      return {
        'color': Colors.green,
        'icon': Icons.trending_up_rounded,
        'sentiment': 'BULLISH'
      };
    } else {
      print('🟠 DIRECT: TIE -> NEUTRAL');
      return {
        'color': Colors.orange,
        'icon': Icons.warning_rounded,
        'sentiment': 'NEUTRAL'
      };
    }
  }

  Widget _buildHistoryItem(BuildContext context, bool isDark, int index,
      String coinName, String text, int timestamp, Map<String, dynamic> style) {
    final cardColor = style['color'] as Color;
    final icon = style['icon'] as IconData;
    final sentiment = style['sentiment'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF393E46).withOpacity(0.5)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                coinName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFDFD0B8)
                      : const Color(0xFF222831),
                  fontFamily: 'DMSerif',
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                sentiment,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: cardColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatHistoryTimestamp(timestamp),
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
                fontFamily: 'DMSerif',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
                height: 1.4,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
            size: 20,
          ),
          onPressed: () => _deleteSingleItem(index),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF222831).withOpacity(0.3)
                  : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF393E46).withOpacity(0.3)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
          ),
          const SizedBox(height: 16),
          Text(
            'No Analysis History',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your AI analysis results will appear here',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              fontFamily: 'DMSerif',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatHistoryTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildAnalysisCard(String analysis, bool isDark) {
    Color cardColor = const Color(0xFF948979);
    IconData icon = Icons.show_chart;
    Color iconColor = Colors.white;

    final analysisLower = analysis.toLowerCase();

    // Önce kesin neutral kontrol et
    if (analysisLower.contains('market condition: neutral') ||
        analysisLower.contains('1) market condition: neutral') ||
        analysisLower.contains('neutral zone') ||
        (analysisLower.contains('neutral') &&
            !analysisLower.contains('bias'))) {
      cardColor = Colors.orange;
      icon = Icons.warning_rounded;
      return _buildAnalysisCardUI(analysis, cardColor, icon, iconColor, isDark);
    }

    // Skorlama sistemi - her kelime için puan ver
    int bullishScore = 0;
    int bearishScore = 0;
    int neutralScore = 0;

    // Güçlü bearish sinyaller (yüksek puan)
    if (analysisLower.contains('bearish')) bearishScore += 5;
    if (analysisLower.contains('sell')) bearishScore += 4;
    if (analysisLower.contains('market condition: bearish')) bearishScore += 6;
    if (analysisLower.contains('negative')) bearishScore += 3;
    if (analysisLower.contains('downtrend')) bearishScore += 3;
    if (analysisLower.contains('decline')) bearishScore += 3;
    if (analysisLower.contains('resistance')) bearishScore += 2;
    if (analysisLower.contains('overbought')) bearishScore += 2;
    if (analysisLower.contains('correction')) bearishScore += 2;
    if (analysisLower.contains('caution')) bearishScore += 1;
    if (analysisLower.contains('concerns')) bearishScore += 2;
    if (analysisLower.contains('risk')) bearishScore += 1;

    // Güçlü bullish sinyaller (yüksek puan)
    if (analysisLower.contains('bullish')) {
      // "slight bullish" vs "strong bullish" ayrımı
      if (analysisLower.contains('slight bullish') ||
          analysisLower.contains('minor bullish')) {
        bullishScore += 2; // Daha az puan
      } else {
        bullishScore += 5; // Normal bullish
      }
    }
    if (analysisLower.contains('buy')) bullishScore += 4;
    if (analysisLower.contains('market condition: bullish')) bullishScore += 6;
    if (analysisLower.contains('positive')) bullishScore += 3;
    if (analysisLower.contains('uptrend')) bullishScore += 3;
    if (analysisLower.contains('support')) bullishScore += 2;
    if (analysisLower.contains('oversold')) bullishScore += 2;
    if (analysisLower.contains('accumulate')) bullishScore += 3;
    if (analysisLower.contains('opportunity')) bullishScore += 1;

    // Neutral sinyaller - yüksek puan
    if (analysisLower.contains('neutral')) neutralScore += 6;
    if (analysisLower.contains('sideways')) neutralScore += 4;
    if (analysisLower.contains('range')) neutralScore += 3;
    if (analysisLower.contains('consolidation')) neutralScore += 3;
    if (analysisLower.contains('hold')) neutralScore += 3;
    if (analysisLower.contains('wait')) neutralScore += 2;
    if (analysisLower.contains('mixed')) neutralScore += 2;
    if (analysisLower.contains('prudent to wait')) neutralScore += 3;

    // RSI değerini de hesaba kat
    if (_rsi > 70) bearishScore += 2;
    if (_rsi < 30) bullishScore += 2;
    if (_rsi >= 40 && _rsi <= 60) neutralScore += 2; // RSI neutral zone

    // Debug için skorları yazdır
    print('Analysis: ${analysisLower.substring(0, 50)}...');
    print(
        'Scores - Bearish: $bearishScore, Bullish: $bullishScore, Neutral: $neutralScore');

    // En yüksek skora göre karar ver
    if (neutralScore >= bearishScore &&
        neutralScore >= bullishScore &&
        neutralScore > 0) {
      cardColor = Colors.orange;
      icon = Icons.warning_rounded;
    } else if (bearishScore > bullishScore && bearishScore > neutralScore) {
      cardColor = Colors.red;
      icon = Icons.trending_down_rounded;
    } else if (bullishScore > bearishScore && bullishScore > neutralScore) {
      cardColor = Colors.green;
      icon = Icons.trending_up_rounded;
    } else {
      // Eşitlik durumunda neutral
      cardColor = Colors.orange;
      icon = Icons.warning_rounded;
    }

    return _buildAnalysisCardUI(analysis, cardColor, icon, iconColor, isDark);
  }

  Widget _buildAnalysisCardUI(String analysis, Color cardColor, IconData icon,
      Color iconColor, bool isDark) {
    return AnimatedBuilder(
      animation: _formAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _formAnimation.value)),
          child: Opacity(
            opacity: _formAnimation.value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cardColor.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cardColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: cardColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Latest Analysis Result',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFFDFD0B8)
                                    : const Color(0xFF222831),
                                fontFamily: 'DMSerif',
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (_selectedCoin != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: cardColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _selectedCoin!.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: cardColor,
                                    fontFamily: 'DMSerif',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF222831).withOpacity(0.3)
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      analysis,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'DMSerif',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
