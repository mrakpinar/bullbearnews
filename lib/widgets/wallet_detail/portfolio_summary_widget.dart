import 'package:flutter/material.dart';

class PortfolioSummaryWidget extends StatelessWidget {
  final bool isDark;
  final bool isLoadingCrypto;
  final double currentValue;
  final double profitLoss;
  final double totalInvestmentValue;
  final int assetCount;
  final String fontFamily;

  const PortfolioSummaryWidget({
    super.key,
    required this.isDark,
    required this.isLoadingCrypto,
    required this.currentValue,
    required this.profitLoss,
    required this.totalInvestmentValue,
    required this.assetCount,
    this.fontFamily = 'DMSerif',
  });

  @override
  Widget build(BuildContext context) {
    final isProfit = profitLoss >= 0;
    final profitLossPercentage = totalInvestmentValue > 0
        ? (profitLoss / totalInvestmentValue) * 100
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? Colors.grey[800]! : Colors.white,
            isDark ? Colors.grey[900]! : Colors.grey[50]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          tileMode: TileMode.clamp,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Value',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontFamily: fontFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLoadingCrypto
                        ? 'Loading...'
                        : '\$${currentValue.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                      fontFamily: fontFamily,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      (isProfit ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        (isProfit ? Colors.green : Colors.red).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isProfit ? Icons.trending_up : Icons.trending_down,
                      color: isProfit ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isProfit ? '+' : ''}\$${profitLoss.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isProfit ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontFamily: fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Invested',
                '\$${totalInvestmentValue.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                Colors.blue,
                isDark,
              ),
              _buildStatItem(
                'Assets',
                '$assetCount',
                Icons.pie_chart,
                Colors.orange,
                isDark,
              ),
              _buildStatItem(
                'Change',
                '${isProfit ? '+' : ''}${profitLossPercentage.toStringAsFixed(1)}%',
                isProfit ? Icons.arrow_upward : Icons.arrow_downward,
                isProfit ? Colors.green : Colors.red,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
            fontFamily: fontFamily,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
            fontFamily: fontFamily,
          ),
        ),
      ],
    );
  }
}
