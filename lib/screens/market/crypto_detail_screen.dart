import 'dart:async';

import 'package:bullbearnews/models/price_alert_model.dart';
import 'package:bullbearnews/services/firebase_favorites_service.dart';
import 'package:bullbearnews/services/price_alert_service.dart';
import 'package:bullbearnews/widgets/crypto_details/crypto_alerts_dialog.dart';
import 'package:bullbearnews/widgets/crypto_details/crypto_auto_analysis_card.dart';
import 'package:bullbearnews/widgets/crypto_details/crypto_detail_header.dart';
import 'package:bullbearnews/widgets/crypto_details/crypto_market_details_card.dart';
import 'package:bullbearnews/widgets/crypto_details/crypto_price_alert_card.dart';
import 'package:bullbearnews/widgets/crypto_details/crypto_price_chart.dart';
import 'package:flutter/material.dart';
import '../../models/crypto_model.dart';

class CryptoDetailScreen extends StatefulWidget {
  final CryptoModel crypto;

  const CryptoDetailScreen({super.key, required this.crypto});

  @override
  State<CryptoDetailScreen> createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen>
    with TickerProviderStateMixin {
  final TextEditingController _priceAlertController = TextEditingController();
  final PriceAlertService _priceAlertService = PriceAlertService();
  final FirebaseFavoritesService _favoritesService = FirebaseFavoritesService();

  late Stream<List<PriceAlert>> _priceAlertsStream;
  late CryptoModel _crypto;
  Set<String> _favoriteCryptos = {};
  String _selectedAlertType = 'above';
  bool _isInitialized = false;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<Set<String>>? _favoritesSubscription;

  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _hideAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _contentAnimation;
  late Animation<double> _hideAnimation;

  bool _isHeaderVisible = true;
  double _lastScrollOffset = 0;
  static const double _scrollThreshold = 50.0;

  @override
  void initState() {
    super.initState();
    _crypto = widget.crypto;
    _priceAlertController.text = _crypto.currentPrice.toString();
    _initializeAnimations();
    _setupScrollListener();
    _initializeData();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _hideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _headerAnimationController, curve: Curves.easeOut),
    );
    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _contentAnimationController, curve: Curves.easeOut),
    );
    _hideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _hideAnimationController, curve: Curves.easeInOut),
    );

    _headerAnimationController.forward();
    _hideAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _contentAnimationController.forward();
      }
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final currentScrollOffset = _scrollController.offset;
      final scrollDelta = currentScrollOffset - _lastScrollOffset;

      if (scrollDelta > _scrollThreshold && _isHeaderVisible) {
        setState(() {
          _isHeaderVisible = false;
        });
        _hideAnimationController.reverse();
      } else if (scrollDelta < -_scrollThreshold && !_isHeaderVisible) {
        setState(() {
          _isHeaderVisible = true;
        });
        _hideAnimationController.forward();
      }

      if (scrollDelta.abs() > _scrollThreshold) {
        _lastScrollOffset = currentScrollOffset;
      }
    });
  }

  @override
  void dispose() {
    _priceAlertController.dispose();
    _scrollController.dispose();
    _favoritesSubscription?.cancel();
    _headerAnimationController.dispose();
    _contentAnimationController.dispose();
    _hideAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      await Future.wait([
        _loadFavorites(),
        _loadPriceAlerts(),
      ]);
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Initialization error: $e');
      setState(() => _isInitialized = true);
    }
  }

  Future<void> _loadFavorites() async {
    try {
      // Firebase'den favorileri al
      final favorites = await _favoritesService.getFavoriteCryptos();

      // Realtime updates için stream dinle
      _favoritesSubscription?.cancel();
      _favoritesSubscription = _favoritesService.watchFavoriteCryptos().listen(
        (favorites) {
          if (mounted) {
            setState(() {
              _favoriteCryptos = favorites;
              _crypto.isFavorite = _favoriteCryptos.contains(_crypto.id);
            });
          }
        },
        onError: (error) {
          debugPrint('Favorites stream error: $error');
        },
      );

      if (mounted) {
        setState(() {
          _favoriteCryptos = favorites;
          _crypto.isFavorite = _favoriteCryptos.contains(_crypto.id);
        });
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      // Hata durumunda mevcut durumu koru
      if (mounted) {
        setState(() {
          _favoriteCryptos = <String>{};
          _crypto.isFavorite = false;
        });
      }
    }
  }

  Future<void> _loadPriceAlerts() async {
    try {
      _priceAlertsStream = _priceAlertService.getAlertsForCrypto(_crypto.id);
    } catch (e) {
      debugPrint('Error loading price alerts: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      // Optimistic update - UI'ı hemen güncelle
      final wasInFavorites = _crypto.isFavorite;
      setState(() {
        _crypto.isFavorite = !_crypto.isFavorite;
        if (_crypto.isFavorite) {
          _favoriteCryptos.add(_crypto.id);
        } else {
          _favoriteCryptos.remove(_crypto.id);
        }
      });

      // Firebase'e kaydet
      await _favoritesService.toggleFavoriteCrypto(_crypto.id);

      // Başarılı mesajı göster
      if (mounted) {
        _showSnackBar(
          wasInFavorites
              ? '${_crypto.name} removed from favorites'
              : '${_crypto.name} added to favorites',
        );
      }
    } catch (e) {
      // Hata durumunda UI'ı geri al
      setState(() {
        _crypto.isFavorite = !_crypto.isFavorite;
        if (_crypto.isFavorite) {
          _favoriteCryptos.add(_crypto.id);
        } else {
          _favoriteCryptos.remove(_crypto.id);
        }
      });

      // Hata mesajı göster
      if (mounted) {
        _showSnackBar('Failed to update favorite: $e', isError: true);
      }
    }
  }

  Future<void> _addPriceAlert() async {
    double? alertPrice = double.tryParse(_priceAlertController.text);

    if (alertPrice == null) {
      _showSnackBar('Please enter a valid price', isError: true);
      return;
    }

    double currentPrice = _crypto.currentPrice;

    if (_selectedAlertType == 'above' && alertPrice <= currentPrice) {
      _showSnackBar('Target price must be higher than current price',
          isError: true);
      return;
    }

    if (_selectedAlertType == 'below' && alertPrice >= currentPrice) {
      _showSnackBar('Target price must be lower than current price',
          isError: true);
      return;
    }

    final newAlert = PriceAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cryptoId: _crypto.id,
      cryptoSymbol: _crypto.symbol,
      targetPrice: alertPrice,
      isAbove: _selectedAlertType == 'above',
      createdAt: DateTime.now(),
    );

    try {
      await _priceAlertService.addAlert(newAlert);
      _showSnackBar(
        'Alert set for ${_crypto.symbol.toUpperCase()} ${_selectedAlertType == 'above' ? 'above' : 'below'} \$${_formatPrice(alertPrice)}',
      );
    } catch (e) {
      _showSnackBar('Failed to save alert: $e', isError: true);
    }
  }

  Future<void> _removeAlert(String alertId) async {
    try {
      await _priceAlertService.removeAlert(alertId);
      _showSnackBar('Alert removed successfully');
    } catch (e) {
      _showSnackBar('Failed to remove alert: $e', isError: true);
    }
  }

  void _showAlertsDialog() {
    showDialog(
      context: context,
      builder: (context) => CryptoAlertsDialog(
        crypto: _crypto,
        priceAlertService: _priceAlertService,
        onRemoveAlert: _removeAlert,
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
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

  String _formatPrice(double price) {
    if (price.isNaN || price.isInfinite || price < 0) {
      return 'N/A';
    }
    if (price == 0) {
      return '0.00';
    }

    if (price < 1) {
      return price
          .toStringAsFixed(6)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    } else if (price < 1000) {
      return price
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    } else {
      return price.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF222831) : const Color(0xFFDFD0B8),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF222831) : const Color(0xFFDFD0B8),
      body: SafeArea(
        child: Column(
          children: [
            // Header Widget
            CryptoDetailHeader(
              crypto: _crypto,
              hideAnimation: _hideAnimation,
              headerAnimation: _headerAnimation,
              onToggleFavorite: _toggleFavorite,
              onShowAlerts: _showAlertsDialog,
              onBack: () => Navigator.pop(context),
            ),

            // Content
            Expanded(
              child: AnimatedBuilder(
                animation: _contentAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - _contentAnimation.value)),
                    child: Opacity(
                      opacity: _contentAnimation.value,
                      child: RefreshIndicator(
                        onRefresh: _initializeData,
                        color: isDark
                            ? const Color(0xFF948979)
                            : const Color(0xFF393E46),
                        backgroundColor: isDark
                            ? const Color(0xFF393E46)
                            : const Color(0xFFDFD0B8),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          child: Column(
                            children: [
                              // Price Chart Widget
                              CryptoPriceChart(crypto: _crypto),
                              const SizedBox(height: 20),

                              // Auto Analysis Card Widget
                              CryptoAutoAnalysisCard(crypto: _crypto),
                              const SizedBox(height: 20),

                              // Price Alert Card Widget
                              CryptoPriceAlertCard(
                                crypto: _crypto,
                                priceAlertController: _priceAlertController,
                                selectedAlertType: _selectedAlertType,
                                priceAlertsStream: _priceAlertsStream,
                                onAlertTypeChanged: (value) {
                                  setState(() {
                                    _selectedAlertType = value;
                                    _priceAlertController.text =
                                        _crypto.currentPrice.toString();
                                  });
                                },
                                onAddAlert: _addPriceAlert,
                              ),
                              const SizedBox(height: 20),

                              // Market Details Card Widget
                              CryptoMarketDetailsCard(crypto: _crypto),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
