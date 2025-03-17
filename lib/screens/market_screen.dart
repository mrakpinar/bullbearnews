import 'package:bullbearnews/screens/crypto_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/crypto_model.dart';
import '../services/crypto_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadFavorites().then((_) => _loadCryptoData());
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

  DateTime _lastRefreshTime =
      DateTime.now().subtract(const Duration(minutes: 1));

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
    if (now.difference(_lastRefreshTime).inSeconds < 10) {
      // 10 saniyeden daha kısa sürede yenileme yapmayı engelle
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please wait a moment and try again (10 sec.)')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      _cryptoList = await _cryptoService.getCryptoData();

      // Favori durumunu kriptolara uygula
      for (var crypto in _cryptoList) {
        crypto.isFavorite = _favoriteCryptos.contains(crypto.id);
      }

      _errorMessage = '';
      _lastRefreshTime = now; // Yenileme zamanını güncelle
      _filterCryptoList(); // Yeni verileri filtrele ve sırala
    } catch (e) {
      _errorMessage = 'An error occurred while loading data: $e';
      print(_errorMessage);
    } finally {
      if (mounted) {
        // Check if widget is still mounted before calling setState
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crypto Market',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: IconButton(
              icon: const Icon(Icons.refresh_sharp),
              onPressed: _loadCryptoData,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama çubuğu
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search crypto...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterCryptoList();
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
                            child: ListView.builder(
                              itemCount: _filteredList.length,
                              itemBuilder: (context, index) {
                                final crypto = _filteredList[index];
                                final isPositive =
                                    crypto.priceChangePercentage24h >= 0;

                                return InkWell(
                                  onTap: () {
                                    // Coin detay sayfasına yönlendir
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CryptoDetailScreen(crypto: crypto),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        children: [
                                          // Leading - Crypto image
                                          SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: Image.network(
                                              crypto.image,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return const Icon(
                                                    Icons.currency_bitcoin,
                                                    size: 40);
                                              },
                                            ),
                                          ),

                                          const SizedBox(width: 12),
                                          // Middle - Crypto name, symbol, market cap
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        crypto.name,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      crypto.symbol
                                                          .toUpperCase(),
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
                                                    color: isDarkMode
                                                        ? Colors.grey[400]
                                                        : Colors.grey[600],
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Right side - Price and change percentage
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      '\$${formatPrice(crypto.currentPrice)}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          isPositive
                                                              ? Icons
                                                                  .arrow_upward
                                                              : Icons
                                                                  .arrow_downward,
                                                          color: isPositive
                                                              ? Colors.green
                                                              : Colors.red,
                                                          size: 16,
                                                        ),
                                                        Text(
                                                          '${isPositive ? '+' : ''}${crypto.priceChangePercentage24h.toStringAsFixed(2)}%',
                                                          style: TextStyle(
                                                            color: isPositive
                                                                ? Colors.green
                                                                : Colors.red,
                                                            fontSize: 14,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(width: 4),
                                                // Favorite button
                                                IconButton(
                                                  icon: Icon(
                                                    crypto.isFavorite
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    color: crypto.isFavorite
                                                        ? Colors.amber
                                                        : isDarkMode
                                                            ? Colors.white
                                                            : Colors.grey,
                                                  ),
                                                  onPressed: () {
                                                    _toggleFavorite(crypto.id);
                                                  },
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  iconSize: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
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
