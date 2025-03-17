// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../models/crypto_model.dart';
import '../services/crypto_service.dart';
import 'crypto_detail_screen.dart'; // CryptoDetailScreen'i ekleyin

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final CryptoService _cryptoService = CryptoService();
  List<CryptoModel> _favoriteCryptos = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadFavoriteCryptos();
  }

  Future<void> _loadFavoriteCryptos() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // Tüm kripto verilerini al
      final List<CryptoModel> allCryptos = await _cryptoService.getCryptoData();

      // Favori ID'lerini al
      final prefs = await SharedPreferences.getInstance();
      final List<String> favoriteIds =
          prefs.getStringList('favoriteCryptos') ?? [];

      // Favorileri filtrele
      _favoriteCryptos = allCryptos
          .where((crypto) => favoriteIds.contains(crypto.id))
          .toList();

      // Market cap'e göre sırala
      _favoriteCryptos.sort((a, b) => b.marketCap.compareTo(a.marketCap));
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred while loading favorites: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Favori kaldırma metodu
  Future<void> _removeFavorite(String cryptoId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> favoriteIds =
          prefs.getStringList('favoriteCryptos') ?? [];

      // ID'yi listeden kaldır
      favoriteIds.remove(cryptoId);

      // Güncellenmiş listeyi kaydet
      await prefs.setStringList('favoriteCryptos', favoriteIds);

      // UI'ı güncelle
      if (mounted) {
        setState(() {
          _favoriteCryptos.removeWhere((crypto) => crypto.id == cryptoId);
        });

        // İşlem başarılı bildirimi göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Crypto removed from favorites.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Hata durumunda bildirim göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occured while loading favorites: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Silme onay dialogu
  Future<void> _showRemoveDialog(CryptoModel crypto) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove from favorites.'),
          content: Text(
              '${crypto.name} (${crypto.symbol.toUpperCase()}) it will be removed from your favorites. Are you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeFavorite(crypto.id);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('Remove'),
            ),
          ],
        );
      },
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

  String formatPrice(double price) {
    return price
        .toStringAsFixed(5)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          // Tema Değiştirme Butonu
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme(); // Tema değiştir
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFavoriteCryptos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Kullanıcı Profil Bilgileri
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Email: ${user?.email ?? 'Not available'}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Favoriler Bölümü
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Favorite Cryptos',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadFavoriteCryptos,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Favori listesi
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage.isNotEmpty
                            ? Center(child: Text(_errorMessage))
                            : _favoriteCryptos.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.star_border,
                                            size: 64,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No favorite crypto added yet.',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'You can add it to your favorites by clicking the star icon on the market page.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _favoriteCryptos.length,
                                    itemBuilder: (context, index) {
                                      final crypto = _favoriteCryptos[index];
                                      final isPositive =
                                          crypto.priceChangePercentage24h >= 0;

                                      return Card(
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        elevation: 2,
                                        child: ListTile(
                                          leading: Image.network(
                                            crypto.image,
                                            height: 40,
                                            width: 40,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Icon(
                                                  Icons.currency_bitcoin,
                                                  size: 40);
                                            },
                                          ),
                                          title: Row(
                                            children: [
                                              Text(
                                                crypto.name,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
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
                                          subtitle: Text(
                                            'Market Cap: \$${_formatNumber(crypto.marketCap)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Fiyat ve değişim bilgisi
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
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
                                                  ),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        isPositive
                                                            ? Icons.arrow_upward
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
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              // Favorilerden kaldırma butonu
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                ),
                                                onPressed: () =>
                                                    _showRemoveDialog(crypto),
                                                tooltip:
                                                    'Remove from favorites',
                                              ),
                                            ],
                                          ),
                                          onTap: () {
                                            // Kripto detay sayfasına yönlendirme
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CryptoDetailScreen(
                                                        crypto: crypto),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
