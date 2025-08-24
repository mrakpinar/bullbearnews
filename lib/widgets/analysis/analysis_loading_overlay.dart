import 'package:bullbearnews/models/crypto_model.dart';
import 'package:flutter/material.dart';

class AnalysisLoadingOverlay extends StatelessWidget {
  final bool isDark;
  final Animation<double> loadingAnimation;
  final CryptoModel? selectedCoin;
  final double rsi;
  final String macd;
  const AnalysisLoadingOverlay(
      {super.key,
      required this.isDark,
      required this.loadingAnimation,
      this.selectedCoin,
      required this.rsi,
      required this.macd});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loadingAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: loadingAnimation.value,
          child: Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF393E46) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF948979),
                            ),
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF948979).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: const Color(0xFF948979),
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Analyzing ${selectedCoin?.name ?? "Cryptocurrency"}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                        fontFamily: 'DMSerif',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI is processing your technical indicators...',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFF948979)
                            : const Color(0xFF393E46),
                        fontFamily: 'DMSerif',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF948979).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '🔍 RSI: ${rsi.round()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF948979),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '📈 MACD: $macd',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF948979),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
