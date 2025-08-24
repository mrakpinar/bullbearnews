import 'package:flutter/material.dart';

class AnalaysisTabBarWidget extends StatelessWidget {
  final bool isDark;
  final List<Map<String, dynamic>> analysisHistory;
  final Animation<double> tabAnimation;
  final TabController tabController;
  final int premiumHistoryCount; // Premium history count ekle

  const AnalaysisTabBarWidget({
    super.key,
    required this.isDark,
    required this.analysisHistory,
    required this.tabAnimation,
    required this.tabController,
    required this.premiumHistoryCount, // Required parameter
  });

  @override
  Widget build(BuildContext context) {
    // Total history count - premium count'u kullan
    final totalHistoryCount = premiumHistoryCount;

    return AnimatedBuilder(
      animation: tabAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - tabAnimation.value)),
          child: Opacity(
            opacity: tabAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF393E46).withOpacity(0.5)
                    : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF948979).withOpacity(0.2)
                      : const Color(0xFF393E46).withOpacity(0.1),
                ),
              ),
              child: TabBar(
                controller: tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF393E46),
                      const Color(0xFF948979),
                    ],
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: Colors.white,
                unselectedLabelColor:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'DMSerif',
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  fontFamily: 'DMSerif',
                ),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text('Analysis'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text('History'),
                        if (totalHistoryCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              totalHistoryCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
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
