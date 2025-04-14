class PriceAlert {
  final String id;
  final String cryptoId;
  final String cryptoSymbol;
  final double targetPrice;
  final bool isAbove; // true = fiyat yükseldiğinde, false = fiyat düştüğünde
  final DateTime createdAt;

  PriceAlert({
    required this.id,
    required this.cryptoId,
    required this.cryptoSymbol,
    required this.targetPrice,
    required this.isAbove,
    required this.createdAt,
  });
}
