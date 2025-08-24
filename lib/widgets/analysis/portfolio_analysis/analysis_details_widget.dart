import 'package:bullbearnews/models/coin_analysis_result.dart';
import 'package:bullbearnews/widgets/analysis/portfolio_analysis/indicator_chip_widget.dart';
import 'package:flutter/material.dart';

class AnalysisDetailsWidget extends StatelessWidget {
  final CoinAnalysisResult analysis; // Nullable değil, non-nullable
  final bool isDark;

  const AnalysisDetailsWidget(
      {super.key, required this.analysis, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color getRSIColor(double rsi) {
      if (rsi > 70) return Colors.red;
      if (rsi < 30) return Colors.green;
      return Colors.orange;
    }

    Color getMACDColor(dynamic macd) {
      // Handle both String and double types
      if (macd is String) {
        final lowerMacd = macd.toLowerCase();
        if (lowerMacd.contains('positive') || lowerMacd.contains('positive')) {
          return Colors.green;
        } else if (lowerMacd.contains('negative') ||
            lowerMacd.contains('negative')) {
          return Colors.red;
        }
        return Colors.orange;
      } else if (macd is double) {
        // For double values, positive is bullish, negative is bearish
        return macd > 0 ? Colors.green : Colors.red;
      }

      return Colors.orange; // Default neutral color
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Technical Indicators
        if (analysis.technicalIndicators.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF222831).withOpacity(0.5)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: const Color(0xFF948979),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Technical Indicators',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                        fontFamily: 'DMSerif',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (analysis.technicalIndicators['rsi'] != null)
                      IndicatorChipWidget(
                        label: 'RSI',
                        value: analysis.technicalIndicators['rsi']
                            .toStringAsFixed(1),
                        color: getRSIColor(analysis.technicalIndicators['rsi']),
                        isDark: isDark,
                      ),
                    if (analysis.technicalIndicators['macd'] != null)
                      IndicatorChipWidget(
                        label: 'MACD',
                        value: analysis.technicalIndicators['macd'].toString(),
                        color:
                            getMACDColor(analysis.technicalIndicators['macd']),
                        isDark: isDark,
                      ),
                    if (analysis.technicalIndicators['price_change_24h'] !=
                        null)
                      IndicatorChipWidget(
                        label: '24H',
                        value:
                            '${analysis.technicalIndicators['price_change_24h'].toStringAsFixed(2)}%',
                        color:
                            analysis.technicalIndicators['price_change_24h'] >=
                                    0
                                ? Colors.green
                                : Colors.red,
                        isDark: isDark,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Analysis Text
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF222831).withOpacity(0.5)
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    analysis.isError
                        ? Icons.error_outline
                        : Icons.psychology_outlined,
                    color:
                        analysis.isError ? Colors.red : const Color(0xFF948979),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    analysis.isError ? 'Analysis Error' : 'AI Analysis',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831),
                      fontFamily: 'DMSerif',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                analysis.analysis,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFFDFD0B8).withOpacity(0.9)
                      : const Color(0xFF222831).withOpacity(0.9),
                  height: 1.4,
                  fontFamily: 'DMSerif',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
