import 'package:bullbearnews/models/crypto_model.dart';

class Wallet {
  final String id;
  final String name;
  final List<WalletItem> items;
  final DateTime createdAt;

  Wallet({
    this.id = '',
    required this.name,
    required this.items,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  // Satın alma fiyatına göre toplam değer
  double get totalInvestmentValue {
    return items.fold<double>(
        0, (sum, item) => sum + (item.amount * item.buyPrice));
  }

  // Güncel fiyatlara göre toplam değer (crypto listesi gerektirir)
  double calculateCurrentValue(List<CryptoModel> allCryptos) {
    return items.fold<double>(0, (sum, item) {
      final crypto = allCryptos.firstWhere(
        (c) => c.id == item.cryptoId,
        orElse: () => CryptoModel(
          id: item.cryptoId,
          name: item.cryptoName,
          symbol: item.cryptoSymbol,
          image: item.cryptoImage,
          currentPrice: 0,
          priceChangePercentage24h: 0,
          marketCap: 0,
          totalVolume: 0,
          circulatingSupply: 0,
          ath: 0,
          atl: 0,
        ),
      );
      return sum + (item.amount * crypto.currentPrice);
    });
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'items': items.map((item) => item.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        id: json['id'] ?? '',
        name: json['name'],
        items: (json['items'] as List<dynamic>?)
                ?.map((item) => WalletItem.fromJson(item))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt']),
      );

  // copyWith metodu eklendi
  Wallet copyWith({
    String? id,
    String? name,
    List<WalletItem>? items,
    DateTime? createdAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class WalletItem {
  final String id;
  final String cryptoId;
  final String cryptoName;
  final String cryptoSymbol;
  final String cryptoImage;
  final double amount;
  final double buyPrice;

  WalletItem({
    this.id = '',
    required this.cryptoId,
    required this.cryptoName,
    required this.cryptoSymbol,
    required this.cryptoImage,
    required this.amount,
    required this.buyPrice,
  });

  Map<String, dynamic> toJson() => {
        'cryptoId': cryptoId,
        'cryptoName': cryptoName,
        'cryptoSymbol': cryptoSymbol,
        'cryptoImage': cryptoImage,
        'amount': amount,
        'buyPrice': buyPrice,
      };

  factory WalletItem.fromJson(Map<String, dynamic> json) => WalletItem(
        id: json['id'] ?? '',
        cryptoId: json['cryptoId'],
        cryptoName: json['cryptoName'],
        cryptoSymbol: json['cryptoSymbol'],
        cryptoImage: json['cryptoImage'],
        amount: json['amount']?.toDouble() ?? 0.0,
        buyPrice: json['buyPrice']?.toDouble() ?? 0.0,
      );

  WalletItem copyWith({
    String? id,
    String? cryptoId,
    String? cryptoName,
    String? cryptoSymbol,
    String? cryptoImage,
    double? amount,
    double? buyPrice,
  }) {
    return WalletItem(
      id: id ?? this.id,
      cryptoId: cryptoId ?? this.cryptoId,
      cryptoName: cryptoName ?? this.cryptoName,
      cryptoSymbol: cryptoSymbol ?? this.cryptoSymbol,
      cryptoImage: cryptoImage ?? this.cryptoImage,
      amount: amount ?? this.amount,
      buyPrice: buyPrice ?? this.buyPrice,
    );
  }
}
