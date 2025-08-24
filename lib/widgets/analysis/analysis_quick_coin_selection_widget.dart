import 'package:bullbearnews/models/crypto_model.dart';
import 'package:flutter/material.dart';

class AnalysisQuickCoinSelectionWidget extends StatelessWidget {
  final Animation<double> formAnimation;
  final bool isDark;
  final CryptoModel? selectedCoin;
  final Function(String) onQuickCoinSelected;

  AnalysisQuickCoinSelectionWidget({
    super.key,
    required this.formAnimation,
    required this.isDark,
    this.selectedCoin,
    required this.onQuickCoinSelected,
  });

  // Quick selection coins
  final List<String> _quickCoins = ['BTC', 'ETH', 'BNB', 'ADA', 'SOL'];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: formAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - formAnimation.value)),
          child: Opacity(
            opacity: formAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF393E46).withOpacity(0.5)
                    : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.flash_on,
                        color: const Color(0xFF948979),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Select',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickCoins.map((symbol) {
                      final isSelected =
                          selectedCoin?.symbol.toUpperCase() == symbol;
                      return GestureDetector(
                        onTap: () => onQuickCoinSelected(symbol),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      const Color(0xFF393E46),
                                      const Color(0xFF948979)
                                    ],
                                  )
                                : null,
                            color: isSelected
                                ? null
                                : (isDark
                                    ? const Color(0xFF222831).withOpacity(0.5)
                                    : const Color(0xFFDFD0B8).withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : const Color(0xFF948979).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            symbol,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? const Color(0xFF948979)
                                      : const Color(0xFF393E46)),
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              fontSize: 14,
                              fontFamily: 'DMSerif',
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
