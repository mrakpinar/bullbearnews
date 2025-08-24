import 'package:flutter/material.dart';

class PremiumInfoCard extends StatelessWidget {
  final bool isDark;
  final Animation<double> formAnimation;
  final VoidCallback showPremiumDialog;
  final int todayAnalysisCount;
  final List<Map<String, dynamic>> analysisHistory;
  const PremiumInfoCard(
      {super.key,
      required this.formAnimation,
      required this.isDark,
      required this.showPremiumDialog,
      required this.todayAnalysisCount,
      required this.analysisHistory});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: formAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - formAnimation.value)),
          child: Opacity(
            opacity: formAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.1),
                    Colors.indigo.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Free Plan Limits',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFDFD0B8)
                                    : const Color(0xFF222831),
                              ),
                            ),
                            Text(
                              '1 analysis per day • 5 history items',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: showPremiumDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.orange, Colors.deepOrange],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Go Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 10,
                                color: const Color(0xFF948979),
                              ),
                            ),
                            const SizedBox(height: 2),
                            LinearProgressIndicator(
                              value: todayAnalysisCount / 1,
                              backgroundColor: Colors.grey.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                todayAnalysisCount >= 1
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$todayAnalysisCount/1 analyses used',
                              style: TextStyle(
                                fontSize: 10,
                                color: todayAnalysisCount >= 1
                                    ? Colors.red
                                    : Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'History',
                              style: TextStyle(
                                fontSize: 10,
                                color: const Color(0xFF948979),
                              ),
                            ),
                            const SizedBox(height: 2),
                            LinearProgressIndicator(
                              value: analysisHistory.length / 5,
                              backgroundColor: Colors.grey.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                analysisHistory.length >= 5
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${analysisHistory.length}/5 items saved',
                              style: TextStyle(
                                fontSize: 10,
                                color: analysisHistory.length >= 5
                                    ? Colors.orange
                                    : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
