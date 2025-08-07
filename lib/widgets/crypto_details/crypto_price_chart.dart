// widgets/crypto_price_chart.dart
import 'package:bullbearnews/screens/market/trading_view_chart.dart';
import 'package:flutter/material.dart';
import '../../../../models/crypto_model.dart';

class CryptoPriceChart extends StatelessWidget {
  final CryptoModel crypto;

  const CryptoPriceChart({
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
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
                        Icons.show_chart,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Price Chart',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                        fontFamily: 'DMSerif',
                      ),
                    ),
                  ],
                ),
                _buildTimeframeSelector(isDark),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: TradingViewChart(
                symbol: crypto.symbol,
                theme: isDark ? 'dark' : 'light',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeframeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF222831).withOpacity(0.5)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final period in ['1D', '1W', '1M', '1Y'])
            Container(
              margin: const EdgeInsets.only(right: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {},
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: period == '1M'
                        ? const Color(0xFF948979)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: period == '1M'
                          ? Colors.white
                          : const Color(0xFF948979),
                      fontFamily: 'DMSerif',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
