import 'package:bullbearnews/screens/market/crypto_detail_screen.dart';
import 'package:flutter/material.dart';
import '../../../models/crypto_model.dart';

class FavoriteCryptosList extends StatefulWidget {
  final bool isLoading;
  final List<CryptoModel> favoriteCryptos;
  final VoidCallback onRefresh;
  final Function(CryptoModel)? onRemoveFavorite;

  const FavoriteCryptosList({
    super.key,
    required this.isLoading,
    required this.favoriteCryptos,
    required this.onRefresh,
    this.onRemoveFavorite,
  });

  @override
  _FavoriteCryptosListState createState() => _FavoriteCryptosListState();
}

class _FavoriteCryptosListState extends State<FavoriteCryptosList> {
  Future<void> _showRemoveFavoriteDialog(CryptoModel crypto) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF393E46) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.star_border_outlined,
                  color: Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Remove Favorite',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF222831),
                    fontFamily: 'DMSerif',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF222831).withOpacity(0.5)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          crypto.image,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.currency_bitcoin,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              crypto.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              crypto.symbol.toUpperCase(),
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to remove this cryptocurrency from your favorites? This action will sync across all your devices.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : const Color(0xFF393E46),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.grey[800] : Colors.grey[200],
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        const SizedBox(width: 8),
                        const Text('Cancel'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (widget.onRemoveFavorite != null) {
                        widget.onRemoveFavorite!(crypto);
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text('Remove'),
                      ],
                    ),
                  ),
                ),
              ],
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
    return _buildCryptoList(context, isDarkMode);
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_border_rounded,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No favorite crypto added yet.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'DMSerif',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add some cryptocurrencies to your favorites\nfrom the market screen',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontFamily: 'DMSerif',
                ),
                textAlign: TextAlign.center,
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
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 400;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF393E46).withOpacity(0.3)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode
                  ? Colors.grey.shade700.withOpacity(0.3)
                  : Colors.grey.shade300.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 20,
              vertical: isSmallScreen ? 8 : 12,
            ),
            leading: Container(
              width: isSmallScreen ? 40 : 45,
              height: isSmallScreen ? 40 : 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.network(
                  crypto.image,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.currency_bitcoin,
                        size: isSmallScreen ? 24 : 28,
                        color: Colors.grey.shade600,
                      ),
                    );
                  },
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    crypto.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 15 : 16,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    crypto.symbol.toUpperCase(),
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      fontSize: isSmallScreen ? 11 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Market Cap: \$${_formatNumber(crypto.marketCap)}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            trailing: SizedBox(
              width: isSmallScreen ? 130 : 150,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${formatPrice(crypto.currentPrice)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 15 : 16,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isPositive ? Colors.green : Colors.red)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPositive
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: isPositive ? Colors.green : Colors.red,
                                size: isSmallScreen ? 12 : 14,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  '${isPositive ? '+' : ''}${crypto.priceChangePercentage24h.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color:
                                        isPositive ? Colors.green : Colors.red,
                                    fontSize: isSmallScreen ? 11 : 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      tooltip: 'Remove from favorites',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      iconSize: isSmallScreen ? 20 : 22,
                      icon: const Icon(Icons.star_rounded, color: Colors.amber),
                      onPressed: () => _showRemoveFavoriteDialog(crypto),
                    ),
                  ),
                ],
              ),
            ),
            onLongPress: () => _showRemoveFavoriteDialog(crypto),
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 300),
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      CryptoDetailScreen(crypto: crypto),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        )),
                        child: child,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
