import 'package:bullbearnews/services/premium_analysis_service.dart';
import 'package:flutter/material.dart';

class PremiumStatusBarWidget extends StatelessWidget {
  final bool isPremium;
  final bool isDark;
  final int premiumHistoryCount;
  final VoidCallback showPremiumDialog;
  final VoidCallback loadPremiumStatus;
  final VoidCallback showErrorSnackBar;
  final int todayAnalysisCount;
  final List<Map<String, dynamic>> analysisHistory;
  const PremiumStatusBarWidget(
      {super.key,
      required this.isPremium,
      required this.isDark,
      required this.premiumHistoryCount,
      required this.showPremiumDialog,
      required this.todayAnalysisCount,
      required this.analysisHistory,
      required this.loadPremiumStatus,
      required this.showErrorSnackBar});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [
                  Colors.orange.withOpacity(0.1),
                  Colors.deepOrange.withOpacity(0.1)
                ]
              : [Colors.blue.withOpacity(0.1), Colors.indigo.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPremium
              ? Colors.orange.withOpacity(0.3)
              : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isPremium ? Colors.orange : Colors.blue,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isPremium ? Icons.workspace_premium : Icons.analytics,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isPremium ? 'Premium User' : 'Free User',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                      ),
                    ),
                    if (isPremium) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '∞',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isPremium
                      ? 'Unlimited analyses • $premiumHistoryCount/50 history'
                      : 'Today: $todayAnalysisCount/1 • ${analysisHistory.length}/5 history',
                  style: TextStyle(
                    fontSize: 11,
                    color: isPremium ? Colors.orange : Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!isPremium) ...[
            GestureDetector(
              onTap: showPremiumDialog,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Upgrade',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: GestureDetector(
                onTap: () async {
                  // Test için premium'u kapat
                  await PremiumAnalysisService.setPremiumStatus(false);
                  loadPremiumStatus;
                  showErrorSnackBar();
                },
                child: Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
