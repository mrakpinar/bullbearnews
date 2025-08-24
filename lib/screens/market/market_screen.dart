import 'dart:async';

import 'package:bullbearnews/screens/market/crypto_detail_screen.dart';
import 'package:bullbearnews/services/firebase_favorites_service.dart';
import 'package:bullbearnews/widgets/market/crypto_list_item.dart';
import 'package:bullbearnews/widgets/market/market_sort_chip.dart';
import 'package:flutter/material.dart';
import '../../models/crypto_model.dart';
import '../../services/crypto_service.dart';
import '../../widgets/market/market_header.dart';
import '../../widgets/market/market_search_bar.dart';
import '../../widgets/market/loading_overlay.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with TickerProviderStateMixin {
  final CryptoService _cryptoService = CryptoService();
  final FirebaseFavoritesService _favoritesService = FirebaseFavoritesService();

  List<CryptoModel> _cryptoList = [];
  List<CryptoModel> _filteredList = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _errorMessage = '';
  SortOption _currentSortOption = SortOption.marketCapDesc;
  String _searchQuery = '';
  Set<String> _favoriteCryptos = {};
  DateTime? _lastRefreshTime;
  List<CryptoModel> _cachedCryptoList = [];
  Timer? _refreshTimer;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<Set<String>>? _favoritesSubscription;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _hideAnimation;
  late AnimationController _refreshAnimationController;
  late Animation<double> _refreshAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadInitialData();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _hideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();

    _refreshAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _refreshAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _refreshAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshTimer?.cancel();
    _favoritesSubscription?.cancel();
    _animationController.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadFavorites();
    await _loadCryptoData();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) _loadCryptoData();
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    // Daha fazla veri yükleme mantığı
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _favoritesService.getFavoriteCryptos();

      _favoritesSubscription?.cancel();
      _favoritesSubscription = _favoritesService.watchFavoriteCryptos().listen(
        (favorites) {
          if (mounted) {
            setState(() {
              _favoriteCryptos = favorites;
              for (var crypto in _cryptoList) {
                crypto.isFavorite = _favoriteCryptos.contains(crypto.id);
              }
              _filterCryptoList();
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
        });
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      if (mounted) {
        setState(() {
          _favoriteCryptos = <String>{};
        });
      }
    }
  }

  Future<void> _toggleFavorite(String id) async {
    try {
      final wasInFavorites = _favoriteCryptos.contains(id);
      if (mounted) {
        setState(() {
          if (wasInFavorites) {
            _favoriteCryptos.remove(id);
          } else {
            _favoriteCryptos.add(id);
          }

          for (var crypto in _cryptoList) {
            crypto.isFavorite = _favoriteCryptos.contains(crypto.id);
          }

          _filterCryptoList();
        });
      }

      await _favoritesService.toggleFavoriteCrypto(id);

      if (mounted) {
        final crypto = _cryptoList.firstWhere((c) => c.id == id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasInFavorites
                  ? '${crypto.name} removed from favorites'
                  : '${crypto.name} added to favorites',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_favoriteCryptos.contains(id)) {
            _favoriteCryptos.remove(id);
          } else {
            _favoriteCryptos.add(id);
          }

          for (var crypto in _cryptoList) {
            crypto.isFavorite = _favoriteCryptos.contains(crypto.id);
          }

          _filterCryptoList();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to update favorite: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _sortCryptoList() {
    switch (_currentSortOption) {
      case SortOption.marketCapDesc:
        _filteredList.sort((a, b) => b.marketCap.compareTo(a.marketCap));
        break;
      case SortOption.priceDesc:
        _filteredList.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
        break;
      case SortOption.priceAsc:
        _filteredList.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
        break;
      case SortOption.changeDesc:
        _filteredList.sort((a, b) =>
            b.priceChangePercentage24h.compareTo(a.priceChangePercentage24h));
        break;
      case SortOption.changeAsc:
        _filteredList.sort((a, b) =>
            a.priceChangePercentage24h.compareTo(b.priceChangePercentage24h));
        break;
      case SortOption.favoritesFirst:
        _filteredList.sort((a, b) {
          if (a.isFavorite && !b.isFavorite) return -1;
          if (!a.isFavorite && b.isFavorite) return 1;
          return b.marketCap.compareTo(a.marketCap);
        });
        break;
    }
  }

  void _filterCryptoList() {
    if (_searchQuery.isEmpty) {
      _filteredList = List.from(_cryptoList);
    } else {
      _filteredList = _cryptoList
          .where((crypto) =>
              crypto.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              crypto.symbol.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    _sortCryptoList();
  }

  void _onSearchChanged(String query) {
    if (mounted) {
      setState(() {
        _searchQuery = query;
        _filterCryptoList();
      });
    }
  }

  void _onSortChanged(SortOption option) {
    setState(() {
      _currentSortOption = option;
      _sortCryptoList();
    });
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    _refreshAnimationController.repeat();

    try {
      await Future.wait([
        _loadCryptoData(forceRefresh: true),
        _loadFavorites(),
      ]);
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      _refreshAnimationController.stop();
      _refreshAnimationController.reset();
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _loadCryptoData({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _lastRefreshTime != null &&
        now.difference(_lastRefreshTime!).inSeconds < 30) {
      if (_cachedCryptoList.isNotEmpty) {
        setState(() {
          _cryptoList = List.from(_cachedCryptoList);
          _filterCryptoList();
          _isLoading = false;
        });
      }
      return;
    }

    if (!_isRefreshing) {
      setState(() => _isLoading = true);
    }

    try {
      final newData = await _cryptoService.getCryptoData();

      for (var crypto in newData) {
        crypto.isFavorite = _favoriteCryptos.contains(crypto.id);
      }

      setState(() {
        _cryptoList = newData;
        _cachedCryptoList = List.from(newData);
        _errorMessage = '';
        _lastRefreshTime = now;
        _filterCryptoList();
      });
    } catch (e) {
      String userFriendlyError;
      if (e.toString().contains('timeout')) {
        userFriendlyError = 'Connection timeout. Please check your internet.';
      } else if (e.toString().contains('limit exceeded')) {
        userFriendlyError = 'API limit reached. Please wait a few minutes.';
      } else {
        userFriendlyError = 'Failed to load data. Please try again.';
      }

      if (_cachedCryptoList.isNotEmpty) {
        setState(() {
          _cryptoList = List.from(_cachedCryptoList);
          _filterCryptoList();
          _errorMessage = '$userFriendlyError Showing cached data.';
        });
      } else {
        if (mounted) {
          setState(() => _errorMessage = userFriendlyError);
        }
      }
    } finally {
      if (mounted && !_isRefreshing) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToDetail(CryptoModel crypto) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            CryptoDetailScreen(crypto: crypto),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _hideAnimation,
                  builder: (context, child) {
                    return ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: _hideAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, -50 * (1 - _hideAnimation.value)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MarketHeader(
                                isDark: isDarkMode,
                                isRefreshing: _isRefreshing,
                                onRefresh: _handleRefresh,
                                headerAnimation: _headerAnimation,
                                refreshAnimation: _refreshAnimation,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                MarketSearchBar(
                  onSearchChanged: _onSearchChanged,
                  isDarkMode: isDarkMode,
                ),
                MarketSortChips(
                  currentSortOption: _currentSortOption,
                  onSortChanged: _onSortChanged,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage.isNotEmpty
                          ? Center(child: Text(_errorMessage))
                          : _filteredList.isEmpty
                              ? const Center(child: Text('No results found!'))
                              : RefreshIndicator(
                                  onRefresh: _loadCryptoData,
                                  child: ListView.separated(
                                    controller: _scrollController,
                                    itemCount: _filteredList.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final crypto = _filteredList[index];
                                      return CryptoListItem(
                                        crypto: crypto,
                                        isDarkMode: isDarkMode,
                                        onTap: () => _navigateToDetail(crypto),
                                        onToggleFavorite: _toggleFavorite,
                                      );
                                    },
                                  ),
                                ),
                ),
              ],
            ),
          ),
          LoadingOverlay(
            isVisible: _isRefreshing,
            refreshAnimation: _refreshAnimation,
          ),
        ],
      ),
    );
  }
}
