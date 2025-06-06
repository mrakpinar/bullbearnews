import 'package:flutter/material.dart';

class CryptoModel {
  final String id;
  final String symbol;
  final String name;
  final String image;
  final double currentPrice;
  final double marketCap;
  final double totalVolume; // 24H Volume
  final double circulatingSupply; // Dolaşımdaki miktar
  final double priceChangePercentage24h;
  final double ath; // All-Time High
  final double atl; // All-Time Low
  bool isFavorite;

  CryptoModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    required this.currentPrice,
    required this.marketCap,
    required this.totalVolume,
    required this.circulatingSupply,
    required this.priceChangePercentage24h,
    required this.ath,
    required this.atl,
    this.isFavorite = false,
  });
  Color get priceChangeColor {
    return priceChangePercentage24h >= 0 ? Colors.green : Colors.red;
  }

  IconData get priceChangeIcon {
    return priceChangePercentage24h >= 0
        ? Icons.arrow_upward
        : Icons.arrow_downward;
  } // Formatlı fiyat değişim yüzdesi

  String get formattedChange {
    return '${priceChangePercentage24h >= 0 ? '+' : ''}${priceChangePercentage24h.toStringAsFixed(2)}%';
  }

  // Formatlı market cap
  String get formattedMarketCap {
    if (marketCap >= 1e12) return '\$${(marketCap / 1e12).toStringAsFixed(2)}T';
    if (marketCap >= 1e9) return '\$${(marketCap / 1e9).toStringAsFixed(2)}B';
    if (marketCap >= 1e6) return '\$${(marketCap / 1e6).toStringAsFixed(2)}M';
    return '\$${marketCap.toStringAsFixed(2)}';
  }

  factory CryptoModel.fromJson(Map<String, dynamic> json) {
    return CryptoModel(
      id: json['id'] ?? '',
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      marketCap: (json['market_cap'] as num?)?.toDouble() ?? 0.0,
      totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0.0,
      circulatingSupply:
          (json['circulating_supply'] as num?)?.toDouble() ?? 0.0,
      priceChangePercentage24h:
          (json['price_change_percentage_24h'] as num?)?.toDouble() ?? 0.0,
      ath: (json['ath'] as num?)?.toDouble() ?? 0.0,
      atl: (json['atl'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'image': image,
      'current_price': currentPrice,
      'market_cap': marketCap,
      'total_volume': totalVolume,
      'circulating_supply': circulatingSupply,
      'price_change_percentage_24h': priceChangePercentage24h,
      'ath': ath,
      'atl': atl,
      'is_favorite': isFavorite,
    };
  }
}
