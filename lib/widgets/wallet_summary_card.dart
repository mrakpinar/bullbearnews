import 'package:flutter/material.dart';

class WalletSummaryCard extends StatelessWidget {
  final double totalPortfolioValue;
  final double totalInvestment;
  final double totalProfitLoss;
  final double totalProfitLossPercentage;
  final VoidCallback onAddToWallet;
  final VoidCallback onShowDetails;

  const WalletSummaryCard({
    super.key,
    required this.totalPortfolioValue,
    required this.totalInvestment,
    required this.totalProfitLoss,
    required this.totalProfitLossPercentage,
    required this.onAddToWallet,
    required this.onShowDetails,
  });

  String _formatNumber(double number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(2)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)}K';
    } else {
      return number.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Wallet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: onAddToWallet,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: InkWell(
            onTap: onShowDetails,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Portfolio Value',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${_formatNumber(totalPortfolioValue)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPortfolioSummaryDetails(isDarkMode),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioSummaryDetails(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invested',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Text(
              '\$${_formatNumber(totalInvestment)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Profit/Loss',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Row(
              children: [
                Icon(
                  totalProfitLoss >= 0
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: totalProfitLoss >= 0 ? Colors.green : Colors.red,
                  size: 16,
                ),
                Text(
                  '\$${_formatNumber(totalProfitLoss.abs())} '
                  '(${totalProfitLossPercentage.toStringAsFixed(2)}%)',
                  style: TextStyle(
                    color: totalProfitLoss >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
