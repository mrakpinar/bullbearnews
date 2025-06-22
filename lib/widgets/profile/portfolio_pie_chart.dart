import 'package:bullbearnews/models/crypto_model.dart';
import 'package:bullbearnews/models/wallet_model.dart';
import 'package:fl_chart/fl_chart.dart'; // Üst kısma ekleyin
import 'package:flutter/material.dart';

class PortfolioPieChart extends StatelessWidget {
  final List<WalletItem> walletItems;
  final List<CryptoModel> allCryptos;

  const PortfolioPieChart({
    super.key,
    required this.walletItems,
    required this.allCryptos,
  });

  @override
  Widget build(BuildContext context) {
    // Verileri hazırla
    final totalValue = walletItems.fold<double>(0, (sum, item) {
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

    // Grafik verilerini hazırla
    final pieData = walletItems.map((item) {
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
      final value = item.amount * crypto.currentPrice;
      final percentage = totalValue > 0 ? (value / totalValue * 100) : 0;

      return PieChartSectionData(
        color: Colors.primaries[
            allCryptos.indexWhere((c) => c.id == item.cryptoId) %
                Colors.primaries.length],
        value: value,
        title:
            '${item.cryptoSymbol.toUpperCase()}\n${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    // Boş portföy durumu
    if (walletItems.isEmpty || pieData.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardTheme.color,
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Text(
            'No portfolio data to display',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    // Grafik widget'ı
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portfolio Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your portfolio distribution by cryptocurrency',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: pieData,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  startDegreeOffset: -90,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
