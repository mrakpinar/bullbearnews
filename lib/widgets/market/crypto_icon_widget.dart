import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/crypto_model.dart';

class CryptoIconWidget extends StatelessWidget {
  final CryptoModel crypto;

  const CryptoIconWidget({
    super.key,
    required this.crypto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: CachedNetworkImage(
        imageUrl: crypto.image,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _getCryptoColor(crypto.symbol),
                  _getCryptoColor(crypto.symbol).withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                crypto.symbol
                    .substring(0, crypto.symbol.length >= 2 ? 2 : 1)
                    .toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
        httpHeaders: const {
          'User-Agent': 'Mozilla/5.0 (compatible; BullBearNews/1.0)',
        },
        cacheManager: null,
        maxHeightDiskCache: 100,
        maxWidthDiskCache: 100,
      ),
    );
  }

  Color _getCryptoColor(String symbol) {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFF45B7D1),
      const Color(0xFF96CEB4),
      const Color(0xFFFECA57),
      const Color(0xFFFF9FF3),
      const Color(0xFF54A0FF),
      const Color(0xFF5F27CD),
      const Color(0xFFFF9F43),
      const Color(0xFF1DD1A1),
    ];

    final hash = symbol.hashCode;
    return colors[hash.abs() % colors.length];
  }
}
