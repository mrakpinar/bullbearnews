import 'package:bullbearnews/models/wallet_model.dart';
import 'package:bullbearnews/models/coin_analysis_result.dart'; // Model import
import 'package:bullbearnews/widgets/analysis/portfolio_analysis/analysis_details_widget.dart';
import 'package:bullbearnews/widgets/analysis/portfolio_analysis/sentiment_chip_widget.dart';
import 'package:flutter/material.dart';

class CoinAnalysisCardWidget extends StatelessWidget {
  final WalletItem item;
  final CoinAnalysisResult? analysis;
  final bool isDark;

  const CoinAnalysisCardWidget(
      {super.key, required this.item, this.analysis, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF393E46) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark
              ? const Color(0xFF948979).withOpacity(0.2)
              : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coin Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.network(
                      item.cryptoImage,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF948979).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Icon(
                          Icons.currency_bitcoin,
                          color: isDark
                              ? const Color(0xFFDFD0B8)
                              : const Color(0xFF393E46),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.cryptoName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFDFD0B8)
                              : const Color(0xFF222831),
                          fontFamily: 'DMSerif',
                        ),
                      ),
                      Text(
                        item.cryptoSymbol.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF948979),
                          fontFamily: 'DMSerif',
                        ),
                      ),
                    ],
                  ),
                ),
                if (analysis != null && !analysis!.isError)
                  SentimentChipWidget(
                    confidence: analysis!.confidence,
                    sentiment: analysis!.sentiment,
                    isDark: isDark,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Analysis Content
            if (analysis == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF222831).withOpacity(0.5)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.pending_outlined,
                      color: const Color(0xFF948979),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Waiting for analysis...',
                      style: TextStyle(
                        color: const Color(0xFF948979),
                        fontFamily: 'DMSerif',
                      ),
                    ),
                  ],
                ),
              )
            else
              AnalysisDetailsWidget(analysis: analysis!, isDark: isDark),
          ],
        ),
      ),
    );
  }
}
