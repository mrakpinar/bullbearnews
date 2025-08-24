import 'package:bullbearnews/models/crypto_model.dart';
import 'package:flutter/material.dart';

class AnalysisAnalysisCard extends StatelessWidget {
  final String analysis;
  final bool isDark;
  final Animation<double> formAnimation;
  final CryptoModel? selectedCoin;
  final double rsi;

  const AnalysisAnalysisCard({
    super.key,
    required this.analysis,
    required this.isDark,
    required this.formAnimation,
    required this.selectedCoin,
    required this.rsi,
  });

  @override
  Widget build(BuildContext context) {
    return _buildAnalysisCard();
  }

  Widget _buildAnalysisCard() {
    Color cardColor = const Color(0xFF948979);
    IconData icon = Icons.show_chart;
    Color iconColor = Colors.white;

    final analysisLower = analysis.toLowerCase();

    // Önce kesin neutral kontrol et
    if (analysisLower.contains('market condition: neutral') ||
        analysisLower.contains('1) market condition: neutral') ||
        analysisLower.contains('neutral zone') ||
        (analysisLower.contains('neutral') &&
            !analysisLower.contains('bias'))) {
      cardColor = Colors.orange;
      icon = Icons.warning_rounded;
      return _buildAnalysisCardUI(cardColor, icon, iconColor);
    }

    // Skorlama sistemi - her kelime için puan ver
    int bullishScore = 0;
    int bearishScore = 0;
    int neutralScore = 0;

    // Güçlü bearish sinyaller (yüksek puan)
    if (analysisLower.contains('bearish')) bearishScore += 5;
    if (analysisLower.contains('sell')) bearishScore += 4;
    if (analysisLower.contains('market condition: bearish')) bearishScore += 6;
    if (analysisLower.contains('negative')) bearishScore += 3;
    if (analysisLower.contains('downtrend')) bearishScore += 3;
    if (analysisLower.contains('decline')) bearishScore += 3;
    if (analysisLower.contains('resistance')) bearishScore += 2;
    if (analysisLower.contains('overbought')) bearishScore += 2;
    if (analysisLower.contains('correction')) bearishScore += 2;
    if (analysisLower.contains('caution')) bearishScore += 1;
    if (analysisLower.contains('concerns')) bearishScore += 2;
    if (analysisLower.contains('risk')) bearishScore += 1;

    // Güçlü bullish sinyaller (yüksek puan)
    if (analysisLower.contains('bullish')) {
      // "slight bullish" vs "strong bullish" ayrımı
      if (analysisLower.contains('slight bullish') ||
          analysisLower.contains('minor bullish')) {
        bullishScore += 2; // Daha az puan
      } else {
        bullishScore += 5; // Normal bullish
      }
    }
    if (analysisLower.contains('buy')) bullishScore += 4;
    if (analysisLower.contains('market condition: bullish')) bullishScore += 6;
    if (analysisLower.contains('positive')) bullishScore += 3;
    if (analysisLower.contains('uptrend')) bullishScore += 3;
    if (analysisLower.contains('support')) bullishScore += 2;
    if (analysisLower.contains('oversold')) bullishScore += 2;
    if (analysisLower.contains('accumulate')) bullishScore += 3;
    if (analysisLower.contains('opportunity')) bullishScore += 1;

    // Neutral sinyaller - yüksek puan
    if (analysisLower.contains('neutral')) neutralScore += 6;
    if (analysisLower.contains('sideways')) neutralScore += 4;
    if (analysisLower.contains('range')) neutralScore += 3;
    if (analysisLower.contains('consolidation')) neutralScore += 3;
    if (analysisLower.contains('hold')) neutralScore += 3;
    if (analysisLower.contains('wait')) neutralScore += 2;
    if (analysisLower.contains('mixed')) neutralScore += 2;
    if (analysisLower.contains('prudent to wait')) neutralScore += 3;

    // RSI değerini de hesaba kat
    if (rsi > 70) bearishScore += 2;
    if (rsi < 30) bullishScore += 2;
    if (rsi >= 40 && rsi <= 60) neutralScore += 2; // RSI neutral zone

    // Debug için skorları yazdır
    print(
        'Analysis: ${analysisLower.substring(0, analysisLower.length > 50 ? 50 : analysisLower.length)}...');
    print(
        'Scores - Bearish: $bearishScore, Bullish: $bullishScore, Neutral: $neutralScore');

    // En yüksek skora göre karar ver
    if (neutralScore >= bearishScore &&
        neutralScore >= bullishScore &&
        neutralScore > 0) {
      cardColor = Colors.orange;
      icon = Icons.warning_rounded;
    } else if (bearishScore > bullishScore && bearishScore > neutralScore) {
      cardColor = Colors.red;
      icon = Icons.trending_down_rounded;
    } else if (bullishScore > bearishScore && bullishScore > neutralScore) {
      cardColor = Colors.green;
      icon = Icons.trending_up_rounded;
    } else {
      // Eşitlik durumunda neutral
      cardColor = Colors.orange;
      icon = Icons.warning_rounded;
    }

    return _buildAnalysisCardUI(cardColor, icon, iconColor);
  }

  Widget _buildAnalysisCardUI(Color cardColor, IconData icon, Color iconColor) {
    return AnimatedBuilder(
      animation: formAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - formAnimation.value)),
          child: Opacity(
            opacity: formAnimation.value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cardColor.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cardColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: cardColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Latest Analysis Result',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFFDFD0B8)
                                    : const Color(0xFF222831),
                                fontFamily: 'DMSerif',
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (selectedCoin != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: cardColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  selectedCoin!.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: cardColor,
                                    fontFamily: 'DMSerif',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF222831).withOpacity(0.3)
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      analysis,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'DMSerif',
                      ),
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
