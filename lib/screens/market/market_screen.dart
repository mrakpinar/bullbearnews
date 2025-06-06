import 'dart:async';

import 'package:bullbearnews/screens/market/crypto_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class _MarketScreenState extends State<MarketScreen> {
  final CryptoService _cryptoService = CryptoService();
  List<CryptoModel> _cryptoList = [];
  List<CryptoModel> _filteredList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  SortOption _currentSortOption = SortOption.marketCapDesc;
  String _searchQuery = '';
  Set<String> _favoriteCryptos = {};
  DateTime? _lastRefreshTime;
  List<CryptoModel> _cachedCryptoList = [];
  Timer? _refreshTimer;
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchDebounce?.cancel();
    _refreshTimer?.cancel();
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
      // Sayfa sonuna ulaşıldı, daha fazla veri yükle
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    // Daha fazla veri yükleme mantığı
  }
  // Favori kriptoları yükle
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteCryptos =
          Set<String>.from(prefs.getStringList('favoriteCryptos') ?? []);
    });
  }

  // Favori durumunu kaydet
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoriteCryptos', _favoriteCryptos.toList());
  }

  // Favori durumunu değiştir
  Future<void> _toggleFavorite(String id) async {
    if (mounted) {
      setState(() {
        if (_favoriteCryptos.contains(id)) {
          _favoriteCryptos.remove(id);
        } else {
          _favoriteCryptos.add(id);
        }

        // Favori durumunu listedeki tüm nesnelere uygula
        for (var crypto in _cryptoList) {
          crypto.isFavorite = _favoriteCryptos.contains(crypto.id);
        }

        // Filtreleme ve sıralama uygula
        _filterCryptoList();
      });
    }
    // Değişiklikleri kaydet
    await _saveFavorites();
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
          return b.marketCap.compareTo(
              a.marketCap); // Favoriler arasında marketCap'e göre sırala
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

  Future<void> _loadCryptoData() async {
    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!).inSeconds < 30) {
      // 30 saniyeden daha kısa sürede yenileme yapmayı engelle
      if (_cachedCryptoList.isNotEmpty) {
        setState(() {
          _cryptoList = List.from(_cachedCryptoList);
          _filterCryptoList();
          _isLoading = false;
        });
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final newData = await _cryptoService.getCryptoData();

      // Favori durumunu kriptolara uygula
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
      // Daha anlaşılır hata mesajları
      String userFriendlyError;
      if (e.toString().contains('timeout')) {
        userFriendlyError = 'Connection timeout. Please check your internet.';
      } else if (e.toString().contains('limit exceeded')) {
        userFriendlyError = 'API limit reached. Please wait a few minutes.';
      } else {
        userFriendlyError = 'Failed to load data. Please try again.';
      }

      // Hata durumunda cache'den veriyi göster
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
      if (mounted) setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crypto Market',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: IconButton(
              icon: const Icon(Icons.refresh_sharp, size: 30), // Refresh icon
              onPressed: _loadCryptoData,
            ),
          ),
        ],
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        toolbarHeight: 60,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Arama çubuğu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
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
                prefixIcon:
                    const Icon(Icons.search, size: 20, color: Colors.grey),
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
              ),
              onChanged: (value) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 500), () {
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

          // Sıralama seçenekleri
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _buildSortChip('Market Cap', SortOption.marketCapDesc),
                _buildSortChip('Highest Price', SortOption.priceDesc),
                _buildSortChip('Lowest price', SortOption.priceAsc),
                _buildSortChip('Most Increased', SortOption.changeDesc),
                _buildSortChip('Most Decreased', SortOption.changeAsc),
                _buildSortChip('Favorites First', SortOption.favoritesFirst),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Kripto listesi
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

                                return _buildCryptoItem(
                                    context, crypto, isDarkMode, isPositive);
                              },
                            ),
                          ),
          ),
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
        color: Theme.of(context).cardColor, // Kart rengi tema ile uyumlu
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
              // Leading - Crypto image
              SizedBox(
                width: 40,
                height: 40,
                child: Image.network(
                  crypto.image,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.currency_bitcoin,
                      size: 40,
                      color: Colors.grey,
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),
              // Middle - Crypto name, symbol, market cap
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
                      'Market Cap: \$${_formatNumber(crypto.marketCap)}',
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

              // Right side - Price and change percentage
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
                    // Favorite button
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

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isDarkMode ? Colors.white : Colors.white)
                : (isDarkMode ? Colors.white : Colors.black),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _currentSortOption = option;
            _sortCryptoList();
          });
        },
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        selectedColor: isDarkMode ? Color(0xFF8A2BE2) : Color(0xFF8A2BE2),
        checkmarkColor: isDarkMode ? Colors.black : Colors.white,
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(2)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)}K';
    } else {
      return number.toString();
    }
  }
}
