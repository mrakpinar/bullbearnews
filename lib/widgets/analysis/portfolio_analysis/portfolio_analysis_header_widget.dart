import 'package:bullbearnews/models/wallet_model.dart';
import 'package:flutter/material.dart';

class PortfolioAnalysisHeaderWidget extends StatelessWidget {
  final bool isDark;
  final Animation<double> headerAnimation;
  final List<WalletItem> walletItems;
  final bool isAnalyzing;
  final VoidCallback analyzeAllCoins;
  const PortfolioAnalysisHeaderWidget(
      {super.key,
      required this.isDark,
      required this.headerAnimation,
      required this.walletItems,
      required this.isAnalyzing,
      required this.analyzeAllCoins});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - headerAnimation.value)),
          child: Opacity(
            opacity: headerAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF393E46).withOpacity(0.8)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF393E46),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Portfolio Analysis',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFFDFD0B8)
                                : const Color(0xFF222831),
                            fontFamily: 'DMSerif',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${walletItems.length} assets to analyze',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFF948979)
                                : const Color(0xFF393E46),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'DMSerif',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isAnalyzing)
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF393E46), Color(0xFF948979)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.analytics_outlined,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: analyzeAllCoins,
                        tooltip: 'Start Analysis',
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
