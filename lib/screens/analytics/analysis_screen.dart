import 'dart:async';

import 'package:bullbearnews/models/crypto_model.dart';
import 'package:bullbearnews/services/analytics_service.dart';
import 'package:bullbearnews/services/crypto_service.dart';
import 'package:bullbearnews/services/premium_analysis_service.dart';
import 'package:bullbearnews/widgets/analysis/analysis_analysis_card.dart';
import 'package:bullbearnews/widgets/analysis/analysis_direct_history_section.dart';
import 'package:bullbearnews/widgets/analysis/analysis_limit_card_widget.dart';
import 'package:bullbearnews/widgets/analysis/analysis_quick_coin_selection_widget.dart';
import 'package:bullbearnews/widgets/analysis/analysis_tab_bar_widget.dart';
import 'package:bullbearnews/widgets/analysis/analysis_loading_overlay.dart';
import 'package:bullbearnews/widgets/analysis/analysis_header.dart';
import 'package:bullbearnews/widgets/analysis/analysis_form.dart';
import 'package:bullbearnews/widgets/analysis/premium_info_card.dart';
import 'package:bullbearnews/widgets/analysis/premium_status_bar_widget.dart';
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

  // Timer'ları bir arada toplayalım
  Timer? _formAnimationDelayTimer;
  Timer? _historyAnimationDelayTimer;
  Timer? _tabAnimationDelayTimer;
  Timer? _searchDebounceTimer; // Arama için debounce timer

  // Coin selection
  List<CryptoModel> _availableCoins = [];
  CryptoModel? _selectedCoin;
  final TextEditingController _coinSearchController = TextEditingController();
  List<CryptoModel> _filteredCoins = [];
  bool _showCoinDropdown = false;

  // Quick selection coins
  static const List<String> _quickCoins = ['BTC', 'ETH', 'BNB', 'ADA', 'SOL'];

  // Cached computed values
  bool? _cachedIsVolumeValid;
  String? _cachedVolumeText;
  bool? _cachedCanAnalyze;

  // Getters - cache edilmiş değerleri kullan
  bool get _isVolumeValid {
    if (_cachedVolumeText != _volumeController.text ||
        _cachedIsVolumeValid == null) {
      _cachedVolumeText = _volumeController.text;
      _cachedIsVolumeValid = double.tryParse(_volumeController.text) != null &&
          double.parse(_volumeController.text) > 0;
    }
    return _cachedIsVolumeValid!;
  }

  bool get _canAnalyze {
    // Cache kontrolü ekleyelim
    _cachedCanAnalyze ??= _selectedCoin != null &&
        _isVolumeValid &&
        !_isLoading &&
        (_isPremium || _remainingAnalyses > 0);
    return _cachedCanAnalyze!;
  }

  // Cache invalidation
  void _invalidateCache() {
    _cachedCanAnalyze = null;
    _cachedIsVolumeValid = null;
    _cachedVolumeText = null;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAnimations();

    // Async işlemleri batch olarak yapalım
    _initializeDataAsync();

    // Volume controller listener ekleyelim
    _volumeController.addListener(_onVolumeChanged);
  }

  // Async initialization işlemlerini batch olarak yapalım
  Future<void> _initializeDataAsync() async {
    await Future.wait([
      _loadPremiumStatus(),
      _loadAnalysisHistory(),
      _loadPremiumHistoryCount(),
      _loadAvailableCoins(),
    ]);

    _setDefaultVolume();
    _updateHistoryCount();
  }

  void _onVolumeChanged() {
    // Debounce ile cache invalidation
    _invalidateCache();

    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {}); // Sadece gerektiğinde rebuild
      }
    });
  }

  void _setDefaultVolume() {
    _volumeController.text = '10000000';
  }

  // Premium history count yükle - optimize edilmiş
  Future<void> _loadPremiumHistoryCount() async {
    try {
      final history = await PremiumAnalysisService.getAnalysisHistory();
      if (mounted) {
        setState(() {
          _premiumHistoryCount = history.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading premium history count: $e');
    }
  }

  // Premium durumunu yükle - optimize edilmiş
  Future<void> _loadPremiumStatus() async {
    try {
      final results = await Future.wait([
        PremiumAnalysisService.isPremiumUser(),
        PremiumAnalysisService.getRemainingAnalyses(),
        PremiumAnalysisService.getTodayAnalysisCount(),
      ]);

      if (mounted) {
        setState(() {
          _isPremium = results[0] as bool;
          _remainingAnalyses = results[1] as int;
          _todayAnalysisCount = results[2] as int;
        });
        _invalidateCache(); // Premium durumu değiştiğinde cache'i invalidate et
      }
    } catch (e) {
      debugPrint('Error loading premium status: $e');
    }
  }

  void _initializeAnimations() {
    // Animation controller'ları tek seferde oluşturalım
    final controllers = <AnimationController>[];

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    controllers.add(_headerAnimationController);

    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    controllers.add(_formAnimationController);

    _historyAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    controllers.add(_historyAnimationController);

    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    controllers.add(_tabAnimationController);

    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    controllers.add(_loadingAnimationController);

    // Animation'ları tek seferde oluşturalım
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

    // Staggered animation'ları başlat
    _startStaggeredAnimations();
  }

  void _startStaggeredAnimations() {
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
        // Sadece ilk 50 coin'i alalım performans için
        _availableCoins = coins.take(100).toList();
        _filteredCoins = _availableCoins;
        _isLoadingCoins = false;

        // Bitcoin'i varsayılan olarak seç
        if (_availableCoins.isNotEmpty) {
          try {
            _selectedCoin = _availableCoins.firstWhere(
              (coin) => coin.symbol.toLowerCase() == 'btc',
            );
          } catch (e) {
            _selectedCoin = _availableCoins.first;
          }
        }
      });

      _invalidateCache();
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
    // Debounce ekleyelim
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      setState(() {
        if (query.isEmpty) {
          _filteredCoins = _availableCoins;
        } else {
          final lowerQuery = query.toLowerCase();
          _filteredCoins = _availableCoins.where((coin) {
            return coin.name.toLowerCase().contains(lowerQuery) ||
                coin.symbol.toLowerCase().contains(lowerQuery);
          }).toList();
        }
      });
    });
  }

  void _onCoinSelected(CryptoModel coin) {
    setState(() {
      _selectedCoin = coin;
      _showCoinDropdown = false;
      _coinSearchController.clear();
      _filteredCoins = _availableCoins;
    });
    _invalidateCache();
  }

  void _onQuickCoinSelected(String symbol) {
    if (_availableCoins.isEmpty) return;

    CryptoModel? coin;
    try {
      coin = _availableCoins.firstWhere(
        (coin) => coin.symbol.toLowerCase() == symbol.toLowerCase(),
      );
    } catch (e) {
      coin = _availableCoins.first;
    }

    _onCoinSelected(coin);
  }

  @override
  void dispose() {
    // Timer'ları temizleyelim
    _formAnimationDelayTimer?.cancel();
    _historyAnimationDelayTimer?.cancel();
    _tabAnimationDelayTimer?.cancel();
    _searchDebounceTimer?.cancel();

    // Animation controller'ları dispose edelim
    _headerAnimationController.dispose();
    _formAnimationController.dispose();
    _historyAnimationController.dispose();
    _tabAnimationController.dispose();
    _loadingAnimationController.dispose();
    _tabController.dispose();

    // Text controller'ları dispose edelim
    _volumeController.removeListener(_onVolumeChanged);
    _volumeController.dispose();
    _coinSearchController.dispose();

    super.dispose();
  }

  Future<void> _loadAnalysisHistory() async {
    try {
      final history = await PremiumAnalysisService.getLegacyAnalysisHistory();
      if (mounted) {
        setState(() => _analysisHistory = history);
      }
    } catch (e) {
      debugPrint('Error loading analysis history: $e');
    }
  }

  Future<void> _saveAnalysisHistory() async {
    try {
      await PremiumAnalysisService.saveLegacyAnalysisHistory(_analysisHistory);
    } catch (e) {
      debugPrint('Error saving analysis history: $e');
    }
  }

  // History count'u güncelle - optimize edilmiş
  Future<void> _updateHistoryCount() async {
    await Future.wait([
      _loadAnalysisHistory(),
      _loadPremiumHistoryCount(),
    ]);
  }

  Future<void> _addAnalysis(String text, String coinName) async {
    try {
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

      await Future.wait([
        _saveAnalysisHistory(),
        _loadPremiumHistoryCount(),
      ]);
    } catch (e) {
      debugPrint('Error adding analysis: $e');
    }
  }

  // Premium kontrol dialogu göster - memoize edilmiş
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
              try {
                // Test için premium aktif et
                await PremiumAnalysisService.setPremiumStatus(true);
                await _loadPremiumStatus();
                Navigator.pop(context);
                _showSuccessSnackBar('🎉 Premium activated for testing!');
              } catch (e) {
                _showErrorSnackBar('Error activating premium: $e');
              }
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
    try {
      // Premium kontrolü
      final canAnalyze = await PremiumAnalysisService.canMakeAnalysis();
      if (!canAnalyze) {
        _showPremiumDialog();
        return null;
      }

      debugPrint('_sendAnalysisRequest başlatıldı');
      debugPrint('Seçilen coin: ${_selectedCoin?.name}');
      debugPrint('RSI: $_rsi');
      debugPrint('MACD: $_macd');
      debugPrint('Volume: ${_volumeController.text}');

      setState(() => _isLoading = true);
      _invalidateCache();
      _loadingAnimationController.forward();

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
      debugPrint('Hata: $e');
      if (mounted) {
        _showErrorSnackBar('❌ Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _invalidateCache();
        _loadingAnimationController.reverse();
      }
    }
    return null;
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
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
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
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
                PremiumStatusBarWidget(
                  isDark: isDark,
                  analysisHistory: _analysisHistory,
                  isPremium: _isPremium,
                  loadPremiumStatus: _loadPremiumStatus,
                  premiumHistoryCount: _premiumHistoryCount,
                  showPremiumDialog: _showPremiumDialog,
                  todayAnalysisCount: _todayAnalysisCount,
                  showErrorSnackBar: () =>
                      _showErrorSnackBar("Deactivated for testing!"),
                ),
                AnalaysisTabBarWidget(
                  isDark: isDark,
                  analysisHistory: _analysisHistory,
                  tabAnimation: _tabAnimation,
                  tabController: _tabController,
                  premiumHistoryCount: _premiumHistoryCount,
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
      onRefresh: () async {
        await Future.wait([
          _loadAnalysisHistory(),
          _loadAvailableCoins(),
          _loadPremiumStatus(),
          _loadPremiumHistoryCount(),
        ]);
      },
      isDark: isDark,
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
          if (!_isPremium)
            PremiumInfoCard(
              isDark: isDark,
              analysisHistory: _analysisHistory,
              formAnimation: _formAnimation,
              showPremiumDialog: _showPremiumDialog,
              todayAnalysisCount: _todayAnalysisCount,
            ),

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
              _invalidateCache();
            },
            onMACDChanged: (value) {
              setState(() {
                _macd = value;
              });
              _invalidateCache();
            },
            onVolumeChanged: (text) {
              // Cache zaten _onVolumeChanged'de invalidate ediliyor
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
            AnalysisLimitCardWidget(
              showPremiumDialog: _showPremiumDialog,
            ),

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

  Widget _buildHistoryTab(bool isDark) {
    return AnalysisDirectHistorySection(
      isDark: isDark,
      historyAnimation: _historyAnimation,
    );
  }
}
