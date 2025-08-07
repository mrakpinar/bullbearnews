// widgets/crypto_market_details_card.dart
import 'package:flutter/material.dart';
import '../../../../models/crypto_model.dart';

class CryptoMarketDetailsCard extends StatelessWidget {
  final CryptoModel crypto;

  const CryptoMarketDetailsCard({
    super.key,
    required this.crypto,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF393E46) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF948979).withOpacity(0.2)
              : const Color(0xFFE0E0E0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 20),
            _buildStatsGrid(isDark),
            const SizedBox(height: 20),
            _buildSupplySection(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF393E46),
                Color(0xFF948979),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.analytics_outlined,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Market Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
            fontFamily: 'DMSerif',
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatItem(
            'Market Cap', '\$${_formatNumber(crypto.marketCap)}', isDark),
        _buildStatItem(
            '24H Volume', '\$${_formatNumber(crypto.totalVolume)}', isDark),
        _buildStatItem(
            'All-Time High', '\$${_formatPrice(crypto.ath)}', isDark),
        _buildStatItem('All-Time Low', '\$${_formatPrice(crypto.atl)}', isDark),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF222831).withOpacity(0.5)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF948979).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF948979),
              fontWeight: FontWeight.w500,
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
              fontFamily: 'DMSerif',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplySection(bool isDark) {
    final circulating = crypto.circulatingSupply;
    final total = crypto.totalVolume;
    final percentCirculating =
        total > 0 ? (circulating / total * 100).clamp(0, 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF222831).withOpacity(0.5)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supply Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Circulating Supply',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF948979),
                        fontWeight: FontWeight.w500,
                        fontFamily: 'DMSerif',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatNumber(circulating)} ${crypto.symbol.toUpperCase()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                        fontFamily: 'DMSerif',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Supply',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF948979),
                        fontWeight: FontWeight.w500,
                        fontFamily: 'DMSerif',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatNumber(total),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                        fontFamily: 'DMSerif',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percentCirculating / 100,
            backgroundColor: const Color(0xFF948979).withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF948979)),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            '${percentCirculating.toStringAsFixed(1)}% of total supply in circulation',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF948979),
              fontFamily: 'DMSerif',
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1e12) return '${(number / 1e12).toStringAsFixed(2)}T';
    if (number >= 1e9) return '${(number / 1e9).toStringAsFixed(2)}B';
    if (number >= 1e6) return '${(number / 1e6).toStringAsFixed(2)}M';
    if (number >= 1e3) return '${(number / 1e3).toStringAsFixed(2)}K';
    return number.toStringAsFixed(2);
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
