import 'package:flutter/material.dart';

class WalletSummaryCard extends StatelessWidget {
  final double totalPortfolioValue;
  final double totalInvestment;
  final double totalProfitLoss;
  final double totalProfitLossPercentage;
  final VoidCallback onAddToWallet;
  final VoidCallback onShowDetails;
  final Future<void> Function()? refreshCallback;

  const WalletSummaryCard({
    super.key,
    required this.totalPortfolioValue,
    required this.totalInvestment,
    required this.totalProfitLoss,
    required this.totalProfitLossPercentage,
    required this.onAddToWallet,
    required this.onShowDetails,
    this.refreshCallback,
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
    final hasData = totalPortfolioValue > 0;
    bool isRefreshing = false;

    return Column(
      children: [
        Card(
          color: Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            ),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Portfolio Summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (hasData)
                      StatefulBuilder(
                        // Refresh durumunu güncellemek için
                        builder: (context, setState) {
                          return IconButton(
                            icon: isRefreshing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh),
                            onPressed: () async {
                              if (refreshCallback != null) {
                                setState(() => isRefreshing = true);
                                try {
                                  await refreshCallback!();
                                } finally {
                                  setState(() => isRefreshing = false);
                                }
                              }
                            },
                          );
                        },
                      )
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Value',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    Text(
                      '\$${totalPortfolioValue.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.amber : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (hasData) _buildPortfolioSummaryDetails(isDarkMode),
                if (!hasData)
                  Center(
                    child: Text(
                      'No assets in portfolio',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                const SizedBox(height: 36),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDarkMode ? Colors.amber : Colors.purpleAccent,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    shadowColor: isDarkMode
                        ? Colors.amber.withOpacity(0.5)
                        : Theme.of(context).primaryColor.withOpacity(0.5),
                    elevation: 4,
                  ),
                  onPressed: onAddToWallet,
                  child: Text(
                    'Add Asset',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.white,
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                      decorationStyle: TextDecorationStyle.solid,
                      decorationThickness: 0,
                      shadows: [
                        Shadow(
                          color: isDarkMode
                              ? Colors.amber.withOpacity(0.5)
                              : Theme.of(context).primaryColor.withOpacity(0.5),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
            Row(
              children: [
                const SizedBox(height: 4),
                const Icon(
                  Icons.arrow_right,
                  size: 16,
                ),
                Text(
                  'Invested',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const SizedBox(width: 6),
                Text(
                  '\$${_formatNumber(totalInvestment)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
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
              mainAxisAlignment: MainAxisAlignment.end,
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
                    fontSize: 16,
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
