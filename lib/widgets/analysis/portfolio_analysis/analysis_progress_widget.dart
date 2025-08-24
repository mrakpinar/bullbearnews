import 'package:flutter/material.dart';

class AnalysisProgressWidget extends StatelessWidget {
  final bool isDark;
  final double analysisProgress;
  final String currentAnalyzingCoin;
  const AnalysisProgressWidget(
      {super.key,
      required this.isDark,
      required this.analysisProgress,
      required this.currentAnalyzingCoin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF393E46) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF948979).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircularProgressIndicator(
                value: analysisProgress,
                color: const Color(0xFF948979),
                strokeWidth: 3,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analyzing Portfolio...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                        fontFamily: 'DMSerif',
                      ),
                    ),
                    if (currentAnalyzingCoin.isNotEmpty)
                      Text(
                        'Current: $currentAnalyzingCoin',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF948979),
                          fontFamily: 'DMSerif',
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${(analysisProgress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF948979),
                  fontFamily: 'DMSerif',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: analysisProgress,
            backgroundColor: const Color(0xFF948979).withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF948979)),
          ),
        ],
      ),
    );
  }
}
