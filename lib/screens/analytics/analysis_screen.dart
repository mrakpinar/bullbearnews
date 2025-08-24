import 'dart:async';

import 'package:bullbearnews/models/crypto_model.dart';
import 'package:bullbearnews/services/analytics_service.dart';
import 'package:bullbearnews/services/crypto_service.dart';
import 'package:bullbearnews/services/premium_analysis_service.dart';
import 'package:bullbearnews/widgets/analysis/analysis_analysis_card.dart';
import 'package:bullbearnews/widgets/analysis/analysis_direct_history_section.dart';
import 'package:bullbearnews/widgets/analysis/analysis_quick_coin_selection_widget.dart';
import 'package:bullbearnews/widgets/analysis/analysis_tab_bar_widget.dart';
import 'package:bullbearnews/widgets/analysis/analysis_loading_overlay.dart';
import 'package:bullbearnews/widgets/analysis/analysis_header.dart';
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
  String _macd = 'positive';
  final TextEditingController _volumeController = TextEditingController();
  String? _lastAnalysis;
  List<Map<String, dynamic>> _analysisHistory = [];
  bool _isLoading = false;
  bool _isLoadingCoins = true;

  // Premium history count için
  int _premiumHistoryCount = 0;

  // Premium durumu
  bool _isPremium = false;
  int _remainingAnalyses = 1;
  int _todayAnalysisCount = 0;

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
      _selectedCoin != null &&
      _isVolumeValid &&
      !_isLoading &&
      (_isPremium || _remainingAnalyses > 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAnimations();
    _loadPremiumStatus();
    _loadAnalysisHistory();
    _loadPremiumHistoryCount();
    _loadAvailableCoins();
    _setDefaultVolume();
    _updateHistoryCount();
  }

  void _setDefaultVolume() {
    _volumeController.text = '10000000';
  }

  // Premium history count yükle
  Future<void> _loadPremiumHistoryCount() async {
    try {
      final history = await PremiumAnalysisService.getAnalysisHistory();
      if (mounted) {
        setState(() {
          _premiumHistoryCount = history.length;
        });
      }
    } catch (e) {
      print('Error loading premium history count: $e');
    }
  }

  // Premium durumunu yükle
  Future<void> _loadPremiumStatus() async {
    final isPremium = await PremiumAnalysisService.isPremiumUser();
    final remaining = await PremiumAnalysisService.getRemainingAnalyses();
    final todayCount = await PremiumAnalysisService.getTodayAnalysisCount();

    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _remainingAnalyses = remaining;
        _todayAnalysisCount = todayCount;
      });
    }
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
    final history = await PremiumAnalysisService.getLegacyAnalysisHistory();
    if (mounted) {
      setState(() => _analysisHistory = history);
    }
  }

  Future<void> _saveAnalysisHistory() async {
    await PremiumAnalysisService.saveLegacyAnalysisHistory(_analysisHistory);
  }

  // History count'u güncelle
  Future<void> _updateHistoryCount() async {
    await _loadAnalysisHistory();
    await _loadPremiumHistoryCount();
  }

  Future<void> _addAnalysis(String text, String coinName) async {
    // Premium analiz kaydetme
    await PremiumAnalysisService.saveLegacyAnalysisToHistory(
      analysis: text,
      coinName: coinName,
      coinSymbol: _selectedCoin?.symbol,
      price: _selectedCoin?.currentPrice,
    );

    // Legacy format için de kaydet
    setState(() {
      _analysisHistory.insert(0, {
        'text': text,
        'coin': coinName,
        'expanded': false,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Free kullanıcılar için limit kontrol
      final maxItems = _isPremium ? 50 : 5;
      if (_analysisHistory.length > maxItems) {
        _analysisHistory = _analysisHistory.take(maxItems).toList();
      }
    });

    await _saveAnalysisHistory();
    // History count'u güncelle
    await _loadPremiumHistoryCount();
  }

  // Premium kontrol dialogu göster
  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF393E46)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.workspace_premium,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Premium Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _remainingAnalyses <= 0
                  ? PremiumAnalysisService.getLimitExceededMessage()
                  : PremiumAnalysisService.getPremiumUpgradeMessage(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Today: $_todayAnalysisCount/1 analyses used',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Test için premium aktif et
              await PremiumAnalysisService.setPremiumStatus(true);
              await _loadPremiumStatus();
              Navigator.pop(context);
              _showSuccessSnackBar('🎉 Premium activated for testing!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Activate Premium',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<String?> _sendAnalysisRequest() async {
    // Premium kontrolü
    final canAnalyze = await PremiumAnalysisService.canMakeAnalysis();
    if (!canAnalyze) {
      _showPremiumDialog();
      return null;
    }

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

        // Analiz sayacını artır (premium olmayan kullanıcılar için)
        if (!_isPremium) {
          await PremiumAnalysisService.incrementAnalysisCount();
          await _loadPremiumStatus(); // Status'u güncelle
        }

        await _addAnalysis(result, _selectedCoin!.name);

        if (mounted) {
          _showSuccessSnackBar('✅ Analysis completed successfully!');
          // Otomatik olarak History tab'ına geç
          _tabController.animateTo(1);
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('❌ Analysis failed. Please try again.');
        }
      }
    } catch (e) {
      print('Hata: $e');
      if (mounted) {
        _showErrorSnackBar('❌ Error: $e');
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
                _buildPremiumStatusBar(isDark),
                AnalaysisTabBarWidget(
                  isDark: isDark,
                  analysisHistory: _analysisHistory,
                  tabAnimation: _tabAnimation,
                  tabController: _tabController,
                  premiumHistoryCount:
                      _premiumHistoryCount, // Premium count ekle
                ),
                Expanded(
                  child: _buildTabBarView(isDark),
                ),
              ],
            ),
          ),
          // Full screen loading overlay
          if (_isLoading)
            AnalysisLoadingOverlay(
              isDark: isDark,
              loadingAnimation: _loadingAnimation,
              macd: _macd,
              rsi: _rsi,
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return AnalyticHeader(
      animation: _headerAnimation,
      onRefresh: () {
        _loadAnalysisHistory();
        _loadAvailableCoins();
        _loadPremiumStatus();
        _loadPremiumHistoryCount(); // Premium count'u da yenile
      },
      isDark: isDark,
    );
  }

  // Premium durum çubuğu
  Widget _buildPremiumStatusBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isPremium
              ? [
                  Colors.orange.withOpacity(0.1),
                  Colors.deepOrange.withOpacity(0.1)
                ]
              : [Colors.blue.withOpacity(0.1), Colors.indigo.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isPremium
              ? Colors.orange.withOpacity(0.3)
              : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _isPremium ? Colors.orange : Colors.blue,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _isPremium ? Icons.workspace_premium : Icons.analytics,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _isPremium ? 'Premium User' : 'Free User',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                      ),
                    ),
                    if (_isPremium) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '∞',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _isPremium
                      ? 'Unlimited analyses • $_premiumHistoryCount/50 history'
                      : 'Today: $_todayAnalysisCount/1 • ${_analysisHistory.length}/5 history',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isPremium ? Colors.orange : Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!_isPremium) ...[
            GestureDetector(
              onTap: _showPremiumDialog,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Upgrade',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: GestureDetector(
                onTap: () async {
                  // Test için premium'u kapat
                  await PremiumAnalysisService.setPremiumStatus(false);
                  await _loadPremiumStatus();
                  _showErrorSnackBar('Premium deactivated for testing');
                },
                child: Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
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
          // Premium bilgilendirme kartı (sadece free kullanıcılar için)
          if (!_isPremium) _buildPremiumInfoCard(isDark),

          // Quick coin selection
          AnalysisQuickCoinSelectionWidget(
            isDark: isDark,
            formAnimation: _formAnimation,
            onQuickCoinSelected: _onQuickCoinSelected,
            selectedCoin: _selectedCoin,
          ),

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

          // Analiz butonu durumu
          if (!_canAnalyze && _selectedCoin != null && _isVolumeValid)
            _buildAnalysisLimitCard(isDark),

          // Son analiz sonucu
          if (_lastAnalysis != null)
            AnalysisAnalysisCard(
              analysis: _lastAnalysis!,
              isDark: isDark,
              formAnimation: _formAnimation,
              selectedCoin: _selectedCoin,
              rsi: _rsi,
            ),
        ],
      ),
    );
  }

  // Premium bilgilendirme kartı
  Widget _buildPremiumInfoCard(bool isDark) {
    return AnimatedBuilder(
      animation: _formAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _formAnimation.value)),
          child: Opacity(
            opacity: _formAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.1),
                    Colors.indigo.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Free Plan Limits',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFDFD0B8)
                                    : const Color(0xFF222831),
                              ),
                            ),
                            Text(
                              '1 analysis per day • 5 history items',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _showPremiumDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.orange, Colors.deepOrange],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Go Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 10,
                                color: const Color(0xFF948979),
                              ),
                            ),
                            const SizedBox(height: 2),
                            LinearProgressIndicator(
                              value: _todayAnalysisCount / 1,
                              backgroundColor: Colors.grey.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _todayAnalysisCount >= 1
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_todayAnalysisCount/1 analyses used',
                              style: TextStyle(
                                fontSize: 10,
                                color: _todayAnalysisCount >= 1
                                    ? Colors.red
                                    : Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'History',
                              style: TextStyle(
                                fontSize: 10,
                                color: const Color(0xFF948979),
                              ),
                            ),
                            const SizedBox(height: 2),
                            LinearProgressIndicator(
                              value: _analysisHistory.length / 5,
                              backgroundColor: Colors.grey.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _analysisHistory.length >= 5
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_analysisHistory.length}/5 items saved',
                              style: TextStyle(
                                fontSize: 10,
                                color: _analysisHistory.length >= 5
                                    ? Colors.orange
                                    : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Analiz limit kartı
  Widget _buildAnalysisLimitCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.block,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Limit Reached',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  'You\'ve used your daily analysis. Upgrade for unlimited access.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showPremiumDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Upgrade',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(bool isDark) {
    return AnalysisDirectHistorySection(
      isDark: isDark,
      historyAnimation: _historyAnimation,
    );
  }
}
