import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/crypto_model.dart';

class CryptoDetailScreen extends StatelessWidget {
  final CryptoModel crypto;

  const CryptoDetailScreen({super.key, required this.crypto});

  @override
  Widget build(BuildContext context) {
    final isPositive = crypto.priceChangePercentage24h >= 0;
    Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(crypto.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coin image and symbol
            _buildCoinHeader(),
            const SizedBox(height: 24),

            // Price information
            _buildPriceSection(isPositive),
            const SizedBox(height: 24),

            // Market details
            _buildMarketDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinHeader() {
    return Center(
      child: Column(
        children: [
          CachedNetworkImage(
            imageUrl: crypto.image,
            width: 100,
            height: 100,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(
              Icons.currency_bitcoin,
              size: 100,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            crypto.symbol.toUpperCase(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(bool isPositive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '\$${_formatPrice(crypto.currentPrice)}',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              color: isPositive ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '${isPositive ? '+' : ''}${crypto.priceChangePercentage24h.toStringAsFixed(2)}%',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMarketDetails() {
    return Column(
      children: [
        _buildDetailRow('Market Cap', '\$${_formatNumber(crypto.marketCap)}'),
        _buildDetailRow('24H Volume', '\$${_formatNumber(crypto.totalVolume)}'),
        _buildDetailRow(
          'Circulating Supply',
          '${_formatNumber(crypto.circulatingSupply)} ${crypto.symbol.toUpperCase()}',
        ),
        _buildDetailRow('All-Time High', '\$${_formatPrice(crypto.ath)}'),
        _buildDetailRow('All-Time Low', '\$${_formatPrice(crypto.atl)}'),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
