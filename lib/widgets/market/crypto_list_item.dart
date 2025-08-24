import 'package:flutter/material.dart';
import '../../models/crypto_model.dart';
import 'crypto_icon_widget.dart';

class CryptoListItem extends StatelessWidget {
  final CryptoModel crypto;
  final bool isDarkMode;
  final VoidCallback onTap;
  final Function(String) onToggleFavorite;

  const CryptoListItem({
    super.key,
    required this.crypto,
    required this.isDarkMode,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = crypto.priceChangePercentage24h >= 0;

    return InkWell(
      onTap: onTap,
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
              CryptoIconWidget(crypto: crypto),
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
                          '\$${_formatPrice(crypto.currentPrice)}',
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
                      onPressed: () => onToggleFavorite(crypto.id),
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

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(5)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
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
