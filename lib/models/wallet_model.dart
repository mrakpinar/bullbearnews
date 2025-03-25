class WalletItem {
  final String cryptoId;
  final String cryptoName;
  final String cryptoSymbol;
  final String cryptoImage;
  final double amount;
  final double buyPrice;

  WalletItem({
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
        cryptoId: json['cryptoId'],
        cryptoName: json['cryptoName'],
        cryptoSymbol: json['cryptoSymbol'],
        cryptoImage: json['cryptoImage'],
        amount: json['amount']?.toDouble() ?? 0.0,
        buyPrice: json['buyPrice']?.toDouble() ?? 0.0,
      );

  WalletItem copyWith({
    String? cryptoId,
    String? cryptoName,
    String? cryptoSymbol,
    String? cryptoImage,
    double? amount,
    double? buyPrice,
  }) {
    return WalletItem(
      cryptoId: cryptoId ?? this.cryptoId,
      cryptoName: cryptoName ?? this.cryptoName,
      cryptoSymbol: cryptoSymbol ?? this.cryptoSymbol,
      cryptoImage: cryptoImage ?? this.cryptoImage,
      amount: amount ?? this.amount,
      buyPrice: buyPrice ?? this.buyPrice,
    );
  }
}
