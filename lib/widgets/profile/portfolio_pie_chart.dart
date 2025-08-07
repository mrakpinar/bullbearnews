import 'package:bullbearnews/models/crypto_model.dart';
import 'package:bullbearnews/models/wallet_model.dart';
import 'package:fl_chart/fl_chart.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Debug log ekleyelim
    print('WalletItems count: ${walletItems.length}');
    print('AllCryptos count: ${allCryptos.length}');
    print('Screen width: $screenWidth, height: $screenHeight');

    // Boş portföy kontrolü
    if (walletItems.isEmpty) {
      return _buildEmptyState(context, 'Your wallet is empty');
    }

    if (allCryptos.isEmpty) {
      return _buildEmptyState(context, 'Crypto data not available');
    }

    // Toplam portföy değerini hesapla
    double totalValue = 0;
    List<Map<String, dynamic>> itemsWithValues = [];

    for (var item in walletItems) {
      final crypto = allCryptos.firstWhere(
        (c) => c.id == item.cryptoId,
        orElse: () {
          print('Crypto not found for: ${item.cryptoId}');
          return CryptoModel(
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
          );
        },
      );

      final value = item.amount * crypto.currentPrice;
      totalValue += value;

      itemsWithValues.add({
        'item': item,
        'crypto': crypto,
        'value': value,
      });

      print(
          '${item.cryptoSymbol}: amount=${item.amount}, price=${crypto.currentPrice}, value=$value');
    }

    print('Total portfolio value: $totalValue');

    // Toplam değer sıfır ise
    if (totalValue <= 0) {
      return _buildEmptyState(context, 'Portfolio value is zero');
    }

    // Pie chart sections oluştur
    List<PieChartSectionData> pieData = [];
    List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    for (int i = 0; i < itemsWithValues.length; i++) {
      final itemData = itemsWithValues[i];
      final item = itemData['item'] as WalletItem;
      final value = itemData['value'] as double;
      final percentage = (value / totalValue * 100);

      // Sadece değeri olan itemleri ekle
      if (value > 0) {
        // Responsive radius ve font size
        final radius = screenWidth < 350 ? 50.0 : 60.0;
        final fontSize = screenWidth < 350 ? 10.0 : 12.0;

        pieData.add(
          PieChartSectionData(
            color: colors[i % colors.length],
            value: value,
            title:
                '${item.cryptoSymbol.toUpperCase()}\n${percentage.toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    // Pie data boş ise
    if (pieData.isEmpty) {
      return _buildEmptyState(context, 'No valid portfolio data');
    }

    // Responsive padding ve chart height
    final cardPadding = screenWidth < 350 ? 12.0 : 16.0;
    final chartHeight = screenWidth < 350 ? 160.0 : 200.0;
    final horizontalPadding = screenWidth < 350 ? 8.0 : 16.0;

    // Ana widget
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).colorScheme.secondary,
          )),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Responsive Total Value section
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: screenWidth < 350
                  ? Column(
                      children: [
                        Text(
                          'Total Value:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${totalValue.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.tertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Total Value:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '\$${totalValue.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.tertiary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: chartHeight,
              child: PieChart(
                PieChartData(
                  sections: pieData,
                  centerSpaceRadius: screenWidth < 350 ? 30 : 40,
                  sectionsSpace: 2,
                  startDegreeOffset: -90,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(itemsWithValues, totalValue, colors, screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    final screenWidth = MediaQuery.of(context).size.width;
    final emptyStateHeight = screenWidth < 350 ? 160.0 : 200.0;

    return Container(
      height: emptyStateHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardTheme.color,
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: screenWidth < 350 ? 40 : 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontSize: screenWidth < 350 ? 12 : 14,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(List<Map<String, dynamic>> itemsWithValues,
      double totalValue, List<Color> colors, double screenWidth) {
    final isSmallScreen = screenWidth < 350;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Holdings',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'DMSerif',
          ),
        ),
        const SizedBox(height: 8),
        ...itemsWithValues.asMap().entries.map((entry) {
          final index = entry.key;
          final itemData = entry.value;
          final item = itemData['item'] as WalletItem;
          final value = itemData['value'] as double;
          final percentage = (value / totalValue * 100);

          if (value <= 0) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: isSmallScreen ? 12 : 16,
                  height: isSmallScreen ? 12 : 16,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: isSmallScreen ? 3 : 2,
                  child: Text(
                    item.cryptoSymbol.toUpperCase(),
                    style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'DMSerif'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: isSmallScreen ? 35 : 45,
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: isSmallScreen ? 2 : 1,
                  child: Text(
                    '\$${value.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
