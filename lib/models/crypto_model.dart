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

  factory CryptoModel.fromJson(Map<String, dynamic> json) {
    return CryptoModel(
      id: json['id'],
      symbol: json['symbol'],
      name: json['name'],
      image: json['image'],
      currentPrice: json['current_price'].toDouble(),
      marketCap: json['market_cap'].toDouble(),
      totalVolume: json['total_volume'].toDouble(),
      circulatingSupply: json['circulating_supply'].toDouble(),
      priceChangePercentage24h: json['price_change_percentage_24h'].toDouble(),
      ath: json['ath'].toDouble(),
      atl: json['atl'].toDouble(),
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
