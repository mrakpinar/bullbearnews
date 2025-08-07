import 'dart:async';

import 'package:bullbearnews/screens/market/crypto_detail_screen.dart';
import 'package:bullbearnews/services/firebase_favorites_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/crypto_model.dart';
import '../../services/crypto_service.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

enum SortOption {
  marketCapDesc,
  priceDesc,
  priceAsc,
  changeDesc,
  changeAsc,
  favoritesFirst,
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
  Timer? _searchDebounce;
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

    // Initialize animations
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
    _searchDebounce?.cancel();
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
      // Firebase'den favorileri al
      final favorites = await _favoritesService.getFavoriteCryptos();

      // Realtime updates için stream dinle
      _favoritesSubscription?.cancel();
      _favoritesSubscription = _favoritesService.watchFavoriteCryptos().listen(
        (favorites) {
          if (mounted) {
            setState(() {
              _favoriteCryptos = favorites;
              // Kripto listesindeki isFavorite durumlarını güncelle
              for (var crypto in _cryptoList) {
                crypto.isFavorite = _favoriteCryptos.contains(crypto.id);
              }
              _filterCryptoList();
            });
          }
        },
        onError: (error) {
          debugPrint('Favorites stream error: $error');
          // Fallback olarak mevcut listeyi kullan
        },
      );

      if (mounted) {
        setState(() {
          _favoriteCryptos = favorites;
        });
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      // Hata durumunda boş set kullan
      if (mounted) {
        setState(() {
          _favoriteCryptos = <String>{};
        });
      }
    }
  }

  Future<void> _toggleFavorite(String id) async {
    try {
      // Optimistic update - UI'ı hemen güncelle
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

      // Firebase'e kaydet
      await _favoritesService.toggleFavoriteCrypto(id);

      // Başarılı mesajı göster
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
      // Hata durumunda UI'ı geri al
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

        // Hata mesajı göster
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

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    _refreshAnimationController.repeat();

    try {
      await Future.wait([
        _loadCryptoData(forceRefresh: true),
        _loadFavorites(), // Favorileri de yenile
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

  String formatPrice(double price) {
    return price
        .toStringAsFixed(5)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
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

  Widget _buildCryptoIcon(CryptoModel crypto) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: CachedNetworkImage(
        imageUrl: crypto.image,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _getCryptoColor(crypto.symbol),
                  _getCryptoColor(crypto.symbol).withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                crypto.symbol
                    .substring(0, crypto.symbol.length >= 2 ? 2 : 1)
                    .toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
        httpHeaders: const {
          'User-Agent': 'Mozilla/5.0 (compatible; BullBearNews/1.0)',
        },
        cacheManager: null,
        maxHeightDiskCache: 100,
        maxWidthDiskCache: 100,
      ),
    );
  }

  Color _getCryptoColor(String symbol) {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFF45B7D1),
      const Color(0xFF96CEB4),
      const Color(0xFFFECA57),
      const Color(0xFFFF9FF3),
      const Color(0xFF54A0FF),
      const Color(0xFF5F27CD),
      const Color(0xFFFF9F43),
      const Color(0xFF1DD1A1),
    ];

    final hash = symbol.hashCode;
    return colors[hash.abs() % colors.length];
  }

  Widget _buildHeader(bool isDark) {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _headerAnimation.value)),
          child: Opacity(
            opacity: _headerAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.trending_up,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Crypto Market',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? const Color(0xFFDFD0B8)
                                    : const Color(0xFF222831),
                                letterSpacing: -0.5,
                                fontFamily: 'DMSerif',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track and analyze cryptocurrency prices',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFF948979)
                                : const Color(0xFF393E46),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'DMSerif',
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _refreshAnimation,
                    builder: (context, child) {
                      return IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isRefreshing
                                ? (isDark ? Colors.blue[700] : Colors.blue[100])
                                : (isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Transform.rotate(
                            angle: _refreshAnimation.value * 2 * 3.14159,
                            child: Icon(
                              Icons.refresh,
                              color: _isRefreshing
                                  ? (isDark
                                      ? Colors.blue[300]
                                      : Colors.blue[600])
                                  : (isDark ? Colors.white : Colors.black),
                              size: 20,
                            ),
                          ),
                        ),
                        onPressed: _isRefreshing ? null : _handleRefresh,
                        tooltip:
                            _isRefreshing ? 'Refreshing...' : 'Refresh data',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    if (!_isRefreshing) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _refreshAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _refreshAnimation.value * 2 * 3.14159,
                    child: Icon(
                      Icons.refresh,
                      size: 32,
                      color: Theme.of(context).primaryColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Refreshing data...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we update the crypto prices',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
                              _buildHeader(isDarkMode),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                  child: TextField(
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    cursorColor: isDarkMode ? Colors.white : Colors.black,
                    cursorHeight: 20,
                    cursorWidth: 2,
                    textAlignVertical: TextAlignVertical.center,
                    textAlign: TextAlign.start,
                    decoration: InputDecoration(
                      hintText: 'Search crypto...',
                      prefixIcon: const Icon(Icons.search,
                          size: 20, color: Colors.grey),
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.grey[800]!
                              : Colors.grey[200]!,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      filled: true,
                      fillColor:
                          isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.grey[800]!
                              : Colors.grey[200]!,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      _searchDebounce?.cancel();
                      _searchDebounce =
                          Timer(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          setState(() {
                            _searchQuery = value;
                            _filterCryptoList();
                          });
                        }
                      });
                    },
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      _buildSortChip('Market Cap', SortOption.marketCapDesc),
                      _buildSortChip('Highest Price', SortOption.priceDesc),
                      _buildSortChip('Lowest price', SortOption.priceAsc),
                      _buildSortChip('Most Increased', SortOption.changeDesc),
                      _buildSortChip('Most Decreased', SortOption.changeAsc),
                      _buildSortChip(
                          'Favorites First', SortOption.favoritesFirst),
                    ],
                  ),
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
                                      final isPositive =
                                          crypto.priceChangePercentage24h >= 0;

                                      return _buildCryptoItem(context, crypto,
                                          isDarkMode, isPositive);
                                    },
                                  ),
                                ),
                ),
              ],
            ),
          ),
          _buildLoadingOverlay(),
        ],
      ),
    );
  }

  InkWell _buildCryptoItem(BuildContext context, CryptoModel crypto,
      bool isDarkMode, bool isPositive) {
    final isPositive = crypto.priceChangePercentage24h >= 0;

    return InkWell(
      onTap: () => _navigateToDetail(crypto),
      child: Card(
        color: Theme.of(context).cardTheme.color,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shadowColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              _buildCryptoIcon(crypto),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            crypto.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          crypto.symbol.toUpperCase(),
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Market Cap: \${_formatNumber(crypto.marketCap)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Volume: \$${_formatNumber(crypto.totalVolume)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '\$${formatPrice(crypto.currentPrice)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              isPositive
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: isPositive ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            Text(
                              '${isPositive ? '+' : ''}${crypto.priceChangePercentage24h.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: isPositive ? Colors.green : Colors.red,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        crypto.isFavorite ? Icons.star : Icons.star_border,
                        color: crypto.isFavorite
                            ? Colors.amber
                            : isDarkMode
                                ? Colors.white
                                : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        _toggleFavorite(crypto.id);
                      },
                      tooltip: crypto.isFavorite
                          ? 'Remove from favorites'
                          : 'Add to favorites',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                      alignment: Alignment.centerRight,
                      splashRadius: 20,
                      highlightColor:
                          isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, SortOption option) {
    final isSelected = _currentSortOption == option;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentSortOption = option;
              _sortCryptoList();
            });
          },
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF393E46),
                        const Color(0xFF948979),
                      ],
                    )
                  : null,
              color: !isSelected
                  ? (isDarkMode
                      ? const Color(0xFF393E46).withOpacity(0.3)
                      : Colors.white.withOpacity(0.7))
                  : null,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : (isDarkMode
                        ? const Color(0xFF948979).withOpacity(0.3)
                        : const Color(0xFF393E46).withOpacity(0.2)),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFDFD0B8)
                    : (isDarkMode
                        ? const Color(0xFF948979)
                        : const Color(0xFF393E46)),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
                fontFamily: 'DMSerif',
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(2)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000000) {
      return '${(number / 1000).toStringAsFixed(2)}K';
    } else {
      return number.toString();
    }
  }
}
