import 'dart:async';

import 'package:bullbearnews/screens/market/crypto_detail_screen.dart';
import 'package:bullbearnews/services/firebase_favorites_service.dart';
import 'package:bullbearnews/widgets/error_state_widget.dart';
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
  // Services
  final CryptoService _cryptoService = CryptoService();
  final FirebaseFavoritesService _favoritesService = FirebaseFavoritesService();

  // Data state
  List<CryptoModel> _cryptoList = [];
  List<CryptoModel> _filteredList = [];
  Set<String> _favoriteCryptos = {};

  // UI state
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasError = false;
  String _errorMessage = '';
  SortOption _currentSortOption = SortOption.marketCapDesc;
  String _searchQuery = '';

  // Cache and timing
  DateTime? _lastRefreshTime;
  List<CryptoModel> _cachedCryptoList = [];
  Timer? _refreshTimer;
  StreamSubscription<Set<String>>? _favoritesSubscription;

  // Controllers
  final ScrollController _scrollController = ScrollController();

  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _refreshAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _hideAnimation;
  late Animation<double> _refreshAnimation;

  // Constants
  static const Duration _refreshInterval = Duration(minutes: 5);
  static const Duration _cacheTimeout = Duration(seconds: 30);
  static const Duration _animationDuration = Duration(milliseconds: 600);
  static const Duration _refreshAnimationDuration =
      Duration(milliseconds: 1000);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
    _loadInitialData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _refreshAnimationController = AnimationController(
      vsync: this,
      duration: _refreshAnimationDuration,
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

    _refreshAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _refreshAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreData();
      }
    });
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
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted && !_isRefreshing) {
        _loadCryptoData();
      }
    });
  }

  Future<void> _loadMoreData() async {
    // Pagination logic can be implemented here
    // For now, just a placeholder
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _favoritesService.getFavoriteCryptos();

      // Setup favorites stream
      _favoritesSubscription?.cancel();
      _favoritesSubscription = _favoritesService.watchFavoriteCryptos().listen(
        (favorites) {
          if (mounted) {
            _updateFavoritesState(favorites);
          }
        },
        onError: (error) {
          debugPrint('Favorites stream error: $error');
        },
      );

      if (mounted) {
        _updateFavoritesState(favorites);
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

  void _updateFavoritesState(Set<String> favorites) {
    setState(() {
      _favoriteCryptos = favorites;
      for (var crypto in _cryptoList) {
        crypto.isFavorite = _favoriteCryptos.contains(crypto.id);
      }
      _filterCryptoList();
    });
  }

  Future<void> _toggleFavorite(String id) async {
    try {
      final wasInFavorites = _favoriteCryptos.contains(id);

      // Optimistic update
      if (mounted) {
        setState(() {
          if (wasInFavorites) {
            _favoriteCryptos.remove(id);
          } else {
            _favoriteCryptos.add(id);
          }
          _updateCryptoFavoriteStatus();
          _filterCryptoList();
        });
      }

      // Actual API call
      await _favoritesService.toggleFavoriteCrypto(id);

      // Show success message
      if (mounted) {
        final crypto = _cryptoList.firstWhere((c) => c.id == id);
        _showSnackBar(
          wasInFavorites
              ? '${crypto.name} removed from favorites'
              : '${crypto.name} added to favorites',
          isError: false,
        );
      }
    } catch (e) {
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          if (_favoriteCryptos.contains(id)) {
            _favoriteCryptos.remove(id);
          } else {
            _favoriteCryptos.add(id);
          }
          _updateCryptoFavoriteStatus();
          _filterCryptoList();
        });

        _showSnackBar('Failed to update favorite: $e', isError: true);
      }
    }
  }

  void _updateCryptoFavoriteStatus() {
    for (var crypto in _cryptoList) {
      crypto.isFavorite = _favoriteCryptos.contains(crypto.id);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
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
        duration: Duration(seconds: isError ? 4 : 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
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
    if (!mounted) return;
    setState(() {
      _searchQuery = query;
      _filterCryptoList();
    });
  }

  void _onSortChanged(SortOption option) {
    if (!mounted) return;
    setState(() {
      _currentSortOption = option;
      _sortCryptoList();
    });
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _hasError = false;
    });

    _refreshAnimationController.repeat();

    try {
      await Future.wait([
        _loadCryptoData(forceRefresh: true),
        _loadFavorites(),
      ]);

      // Small delay for better UX
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
    // Check cache validity
    final now = DateTime.now();
    if (!forceRefresh &&
        _lastRefreshTime != null &&
        now.difference(_lastRefreshTime!).inSeconds < _cacheTimeout.inSeconds) {
      if (_cachedCryptoList.isNotEmpty) {
        setState(() {
          _cryptoList = List.from(_cachedCryptoList);
          _filterCryptoList();
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    if (!_isRefreshing && mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final newData = await _cryptoService.getCryptoData();

      // Update favorite status
      for (var crypto in newData) {
        crypto.isFavorite = _favoriteCryptos.contains(crypto.id);
      }

      if (mounted) {
        setState(() {
          _cryptoList = newData;
          _cachedCryptoList = List.from(newData);
          _errorMessage = '';
          _hasError = false;
          _lastRefreshTime = now;
          _filterCryptoList();
        });
      }
    } catch (e) {
      final userFriendlyError = _parseError(e);

      if (_cachedCryptoList.isNotEmpty) {
        // Show cached data with warning
        if (mounted) {
          setState(() {
            _cryptoList = List.from(_cachedCryptoList);
            _filterCryptoList();
            _errorMessage = '$userFriendlyError Showing cached data.';
            _hasError = false; // Don't show error state, just warning
          });
          _showSnackBar(_errorMessage, isError: false);
        }
      } else {
        // Show error state
        if (mounted) {
          setState(() {
            _errorMessage = userFriendlyError;
            _hasError = true;
          });
        }
      }
    } finally {
      if (mounted && !_isRefreshing) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _parseError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return 'Connection timeout. Please check your internet.';
    } else if (errorString.contains('limit exceeded') ||
        errorString.contains('rate limit')) {
      return 'API limit reached. Please wait a few minutes.';
    } else if (errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'Network error. Please check your connection.';
    } else {
      return 'Failed to load market data. Please try again.';
    }
  }

  Future<void> _retryLoadData() async {
    await _loadCryptoData(forceRefresh: true);
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
                _buildHeader(isDarkMode),
                _buildSearchAndSort(isDarkMode),
                const SizedBox(height: 8),
                Expanded(child: _buildContent(isDarkMode)),
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

  Widget _buildHeader(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _hideAnimation,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _hideAnimation.value,
            child: Transform.translate(
              offset: Offset(0, -50 * (1 - _hideAnimation.value)),
              child: MarketHeader(
                isDark: isDarkMode,
                isRefreshing: _isRefreshing,
                onRefresh: _handleRefresh,
                headerAnimation: _headerAnimation,
                refreshAnimation: _refreshAnimation,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchAndSort(bool isDarkMode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MarketSearchBar(
          onSearchChanged: _onSearchChanged,
          isDarkMode: isDarkMode,
        ),
        MarketSortChips(
          currentSortOption: _currentSortOption,
          onSortChanged: _onSortChanged,
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }

  Widget _buildContent(bool isDarkMode) {
    if (_isLoading && _cryptoList.isEmpty) {
      return _buildLoadingState(isDarkMode);
    }

    if (_hasError && _cryptoList.isEmpty) {
      return ErrorStateWidget(
        isDark: isDarkMode,
        errorMessage: _errorMessage,
        onRetry: _retryLoadData,
      );
    }

    if (_filteredList.isEmpty && _cryptoList.isNotEmpty) {
      return _buildEmptySearchState(isDarkMode);
    }

    if (_filteredList.isEmpty) {
      return _buildEmptyState(isDarkMode);
    }

    return _buildCryptoList();
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF393E46).withOpacity(0.3)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDarkMode ? const Color(0xFF948979) : const Color(0xFF393E46),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading market data...',
            style: TextStyle(
              color: isDarkMode
                  ? const Color(0xFF948979)
                  : const Color(0xFF393E46),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'DMSerif',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color:
                isDarkMode ? const Color(0xFF948979) : const Color(0xFF393E46),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode
                  ? const Color(0xFF948979)
                  : const Color(0xFF393E46),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode
                  ? const Color(0xFF948979).withOpacity(0.7)
                  : const Color(0xFF393E46).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 64,
            color:
                isDarkMode ? const Color(0xFF948979) : const Color(0xFF393E46),
          ),
          const SizedBox(height: 16),
          Text(
            'No market data available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode
                  ? const Color(0xFF948979)
                  : const Color(0xFF393E46),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode
                  ? const Color(0xFF948979).withOpacity(0.7)
                  : const Color(0xFF393E46).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCryptoList() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredList.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final crypto = _filteredList[index];
          return AnimatedContainer(
            duration: Duration(milliseconds: 200 + (index * 50)),
            curve: Curves.easeOutCubic,
            child: CryptoListItem(
              crypto: crypto,
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
              onTap: () => _navigateToDetail(crypto),
              onToggleFavorite: _toggleFavorite,
            ),
          );
        },
      ),
    );
  }
}
