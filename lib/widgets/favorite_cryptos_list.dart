import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/crypto_model.dart';

class FavoriteCryptosList extends StatefulWidget {
  final bool isLoading;
  final List<CryptoModel> favoriteCryptos;
  final VoidCallback onRefresh;

  const FavoriteCryptosList({
    super.key,
    required this.isLoading,
    required this.favoriteCryptos,
    required this.onRefresh,
  });

  @override
  _FavoriteCryptosListState createState() => _FavoriteCryptosListState();
}

class _FavoriteCryptosListState extends State<FavoriteCryptosList> {
  Future<void> _showRemoveFavoriteDialog(CryptoModel crypto) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Favorite'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Are you sure you want to remove ${crypto.name} from your favorites?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
              },
            ),
            TextButton(
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
                _removeFavorite(crypto);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeFavorite(CryptoModel crypto) async {
    final prefs = await SharedPreferences.getInstance();

    // Mevcut favori coinleri al
    List<String> favoriteIds = prefs.getStringList('favoriteCryptos') ?? [];

    // Coin'i favorilerden çıkar
    favoriteIds.remove(crypto.id);

    // Güncellenmiş listeyi kaydet
    await prefs.setStringList('favoriteCryptos', favoriteIds);

    // Refresh çağrısı
    widget.onRefresh();

    // Snackbar ile bilgilendirme
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${crypto.name} removed from favorites'),
        duration: const Duration(seconds: 2),
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
      return number.toStringAsFixed(2);
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

    return Column(
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
              onPressed: widget.onRefresh,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildCryptoList(context, isDarkMode),
      ],
    );
  }

  Widget _buildCryptoList(BuildContext context, bool isDarkMode) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.favoriteCryptos.isEmpty) {
      return Center(
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
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.favoriteCryptos.length,
      itemBuilder: (context, index) {
        final crypto = widget.favoriteCryptos[index];
        final isPositive = crypto.priceChangePercentage24h >= 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            leading: Image.network(
              crypto.image,
              height: 40,
              width: 40,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.currency_bitcoin, size: 40);
              },
            ),
            title: Row(
              children: [
                Text(
                  crypto.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  crypto.symbol.toUpperCase(),
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'Market Cap: \$${_formatNumber(crypto.marketCap)}',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${formatPrice(crypto.currentPrice)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
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
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.star, color: Colors.amber),
                  onPressed: () => _showRemoveFavoriteDialog(crypto),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
