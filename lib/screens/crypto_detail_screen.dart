// screens/crypto_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/crypto_model.dart';

class CryptoDetailScreen extends StatelessWidget {
  final CryptoModel crypto;

  const CryptoDetailScreen({super.key, required this.crypto});

  @override
  Widget build(BuildContext context) {
    final isPositive = crypto.priceChangePercentage24h >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(crypto.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coin resmi ve sembolü
            Center(
              child: Column(
                children: [
                  Image.network(
                    crypto.image,
                    width: 100,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.currency_bitcoin, size: 100);
                    },
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
            ),

            const SizedBox(height: 24),

            // Fiyat bilgisi
            Text(
              '\$${_formatPrice(crypto.currentPrice)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Değişim yüzdesi
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

            const SizedBox(height: 24),

            // Market Cap
            _buildDetailRow(
                'Market Cap', '\$${_formatNumber(crypto.marketCap)}'),

            // 24H Volume
            _buildDetailRow(
                '24H Volume', '\$${_formatNumber(crypto.totalVolume)}'),

            // Circulating Supply
            _buildDetailRow('Circulating Supply',
                '${_formatNumber(crypto.circulatingSupply)} ${crypto.symbol.toUpperCase()}'),

            // All-Time High
            _buildDetailRow('All-Time High', '\$${_formatPrice(crypto.ath)}'),

            // All-Time Low
            _buildDetailRow('All-Time Low', '\$${_formatPrice(crypto.atl)}'),
          ],
        ),
      ),
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

  String _formatPrice(double price) {
    if (price < 1) {
      // Küçük sayılar için 6 ondalık basamak
      return price
          .toStringAsFixed(6)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    } else if (price < 1000) {
      // 1 ile 1000 arasındaki sayılar için 2 ondalık basamak
      return price
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    } else {
      // 1000'den büyük sayılar için tam sayı formatı
      return price.toStringAsFixed(0);
    }
  }
}
