import 'package:bullbearnews/screens/market/trading_view_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/crypto_model.dart';

class CryptoDetailScreen extends StatelessWidget {
  final CryptoModel crypto;

  const CryptoDetailScreen({super.key, required this.crypto});

  @override
  Widget build(BuildContext context) {
    final isPositive = crypto.priceChangePercentage24h >= 0;
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coin header and price info in a card
                  _buildHeaderCard(isPositive, theme),
                  const SizedBox(height: 16),

                  // Price chart
                  _buildPriceChart(),
                  const SizedBox(height: 16),

                  // Market details
                  _buildMarketDetailsCard(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          crypto.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.1),
              ],
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.star_border),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeaderCard(bool isPositive, ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top row with coin image and basic info
            Row(
              children: [
                // Coin image
                Hero(
                  tag: 'crypto-${crypto.id}',
                  child: CachedNetworkImage(
                    imageUrl: crypto.image,
                    width: 60,
                    height: 60,
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.currency_bitcoin,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Symbol and name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crypto.symbol.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        crypto.name,
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 32),

            // Price section
            Row(
              children: [
                // Current price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Price',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${_formatPrice(crypto.currentPrice)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // 24h change
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}${crypto.priceChangePercentage24h.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Price Chart',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildTimeframeSelector(),
              ],
            ),
            const SizedBox(height: 16),
            TradingViewChart(
              symbol: crypto.symbol,
              theme: 'dark',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (final period in ['1D', '1W', '1M', '1Y', 'All'])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: period == '1M' ? Colors.blue : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {},
                child: Text(
                  period,
                  style: TextStyle(
                    fontSize: 12,
                    color: period == '1M' ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMarketDetailsCard(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Market Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildStatItem('Market Cap',
                    '\$${_formatNumber(crypto.marketCap)}', theme),
                _buildStatItem('24H Volume',
                    '\$${_formatNumber(crypto.totalVolume)}', theme),
                _buildStatItem(
                    'All-Time High', '\$${_formatPrice(crypto.ath)}', theme),
                _buildStatItem(
                    'All-Time Low', '\$${_formatPrice(crypto.atl)}', theme),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Supply details
            _buildSupplySection()
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplySection() {
    final circulating = crypto.circulatingSupply;
    final total = crypto
        .totalVolume; // Fallback if null ** Burada supply yerine total volume var doğru mu bilemiyorum.
    final percentCirculating = (circulating / total * 100).clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Supply',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Circulating Supply',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '${_formatNumber(circulating)} ${crypto.symbol.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Supply',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    _formatNumber(total),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: percentCirculating / 100,
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 4),
        Text(
          '${percentCirculating.toStringAsFixed(1)}% of total supply in circulation',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    if (number >= 1e9) return '${(number / 1e9).toStringAsFixed(2)}B';
    if (number >= 1e6) return '${(number / 1e6).toStringAsFixed(2)}M';
    if (number >= 1e3) return '${(number / 1e3).toStringAsFixed(2)}K';
    return number.toStringAsFixed(2);
  }

  String _formatPrice(double price) {
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
