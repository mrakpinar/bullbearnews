// widgets/premium/premium_widgets.dart
import 'package:flutter/material.dart';
import '../../services/premium_analysis_service.dart';

class PremiumWidgets {
  // Premium status badge
  static Widget buildPremiumBadge({
    required bool isPremium,
    double? fontSize,
  }) {
    if (!isPremium) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium,
            color: Colors.white,
            size: (fontSize ?? 12) - 2,
          ),
          const SizedBox(width: 4),
          Text(
            'PREMIUM',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Premium upgrade button
  static Widget buildUpgradeButton({
    required VoidCallback onPressed,
    String text = 'Upgrade',
    double? fontSize,
    EdgeInsets? padding,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.orange, Colors.deepOrange],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rocket_launch,
              color: Colors.white,
              size: (fontSize ?? 14) + 2,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize ?? 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Premium dialog
  static Future<void> showPremiumDialog({
    required BuildContext context,
    String? title,
    String? message,
    int? remainingAnalyses,
    int? todayAnalysisCount,
    bool showTestActivation = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF393E46) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title ?? 'Premium Required',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message ??
                  (remainingAnalyses != null && remainingAnalyses <= 0
                      ? PremiumAnalysisService.getLimitExceededMessage()
                      : PremiumAnalysisService.getPremiumUpgradeMessage()),
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            if (todayAnalysisCount != null) ...[
              const SizedBox(height: 16),
              _buildUsageInfo(todayAnalysisCount, isDark),
            ],
            const SizedBox(height: 20),
            _buildFeaturesList(isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Later',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          if (showTestActivation)
            ElevatedButton(
              onPressed: () async {
                await PremiumAnalysisService.setPremiumStatus(true);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text('🎉 Premium activated for testing!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Activate Premium',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _buildUsageInfo(int todayAnalysisCount, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (todayAnalysisCount >= 1 ? Colors.red : Colors.blue)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (todayAnalysisCount >= 1 ? Colors.red : Colors.blue)
              .withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            todayAnalysisCount >= 1 ? Icons.warning : Icons.info,
            color: todayAnalysisCount >= 1 ? Colors.red : Colors.blue,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Today: $todayAnalysisCount/1 analyses used',
              style: TextStyle(
                fontSize: 12,
                color: todayAnalysisCount >= 1 ? Colors.red : Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildFeaturesList(bool isDark) {
    final features = [
      '🚀 Unlimited daily analyses',
      '📊 50 analysis history (vs 5)',
      '⚡ Priority AI processing',
      '🎯 Advanced indicators',
      '🚫 Ad-free experience',
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.deepOrange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✨ Premium Features:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  feature,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFFDFD0B8)
                        : const Color(0xFF222831),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // Premium limit warning card
  static Widget buildLimitWarningCard({
    required bool isDark,
    required int todayAnalysisCount,
    required int remainingAnalyses,
    required VoidCallback onUpgrade,
  }) {
    final isLimitReached = remainingAnalyses <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isLimitReached ? Colors.red : Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isLimitReached ? Colors.red : Colors.orange).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isLimitReached ? Colors.red : Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isLimitReached ? Icons.block : Icons.warning,
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
                      isLimitReached
                          ? 'Daily Limit Reached'
                          : 'Approaching Limit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isLimitReached ? Colors.red : Colors.orange,
                      ),
                    ),
                    Text(
                      isLimitReached
                          ? 'You\'ve used your daily analysis. Upgrade for unlimited access.'
                          : 'You have $remainingAnalyses analysis remaining today.',
                      style: TextStyle(
                        fontSize: 12,
                        color: (isLimitReached ? Colors.red : Colors.orange)
                            .shade700,
                      ),
                    ),
                  ],
                ),
              ),
              buildUpgradeButton(
                onPressed: onUpgrade,
                fontSize: 11,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: todayAnalysisCount / 1,
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              isLimitReached ? Colors.red : Colors.orange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Usage: $todayAnalysisCount/1 analyses today',
            style: TextStyle(
              fontSize: 10,
              color: isLimitReached ? Colors.red : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Premium feature lock overlay
  static Widget buildFeatureLockOverlay({
    required String featureName,
    required VoidCallback onUpgrade,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock,
            color: Colors.orange,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            featureName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Upgrade to Premium to unlock this feature',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          buildUpgradeButton(
            onPressed: onUpgrade,
            text: 'Unlock Premium',
          ),
        ],
      ),
    );
  }
}
