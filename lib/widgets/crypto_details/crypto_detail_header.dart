// widgets/crypto_detail_header.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../models/crypto_model.dart';

class CryptoDetailHeader extends StatelessWidget {
  final CryptoModel crypto;
  final Animation<double> hideAnimation;
  final Animation<double> headerAnimation;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShowAlerts;
  final VoidCallback onBack;

  const CryptoDetailHeader({
    super.key,
    required this.crypto,
    required this.hideAnimation,
    required this.headerAnimation,
    required this.onToggleFavorite,
    required this.onShowAlerts,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = crypto.priceChangePercentage24h >= 0;

    return AnimatedBuilder(
      animation: hideAnimation,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: hideAnimation.value,
            child: Transform.translate(
              offset: Offset(0, -50 * (1 - hideAnimation.value)),
              child: AnimatedBuilder(
                animation: headerAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - headerAnimation.value)),
                    child: Opacity(
                      opacity: headerAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildActionButton(
                                  icon: Icons.arrow_back_ios_new,
                                  onTap: onBack,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Row(
                                    children: [
                                      _buildCryptoImage(),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildCryptoInfo(isDark),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    _buildActionButton(
                                      icon: crypto.isFavorite
                                          ? Icons.star
                                          : Icons.star_border,
                                      onTap: onToggleFavorite,
                                      isDark: isDark,
                                      isActive: crypto.isFavorite,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildActionButton(
                                      icon: Icons.notifications_none,
                                      onTap: onShowAlerts,
                                      isDark: isDark,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildPriceCard(isDark, isPositive),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCryptoImage() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(
          imageUrl: crypto.image,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (context, url) => const CircularProgressIndicator(),
          errorWidget: (context, url, error) =>
              const Icon(Icons.currency_bitcoin),
        ),
      ),
    );
  }

  Widget _buildCryptoInfo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          crypto.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
            fontFamily: 'DMSerif',
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          crypto.symbol.toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF948979),
            fontWeight: FontWeight.w500,
            fontFamily: 'DMSerif',
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? Colors.yellow.withOpacity(0.4)
            : isDark
                ? const Color(0xFF393E46).withOpacity(0.8)
                : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: isActive
                  ? Colors.yellow[800]
                  : isDark
                      ? const Color(0xFFDFD0B8)
                      : const Color(0xFF393E46),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceCard(bool isDark, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF393E46) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPositive
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Price',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF948979),
                    fontFamily: 'DMSerif',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${_formatPrice(crypto.currentPrice)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFDFD0B8)
                        : const Color(0xFF222831),
                    fontFamily: 'DMSerif',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isPositive
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPositive
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '${isPositive ? '+' : ''}${crypto.priceChangePercentage24h.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'DMSerif',
                  ),
                ),
              ],
            ),
          ),
        ],
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
}
