import 'package:flutter/material.dart';

class MarketHeader extends StatelessWidget {
  final bool isDark;
  final bool isRefreshing;
  final VoidCallback? onRefresh;
  final Animation<double> headerAnimation;
  final Animation<double> refreshAnimation;

  const MarketHeader({
    super.key,
    required this.isDark,
    required this.isRefreshing,
    required this.onRefresh,
    required this.headerAnimation,
    required this.refreshAnimation,
  });

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF393E46),
                                    const Color(0xFF948979),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.trending_up,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Crypto Market',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? const Color(0xFFDFD0B8)
                                    : const Color(0xFF222831),
                                letterSpacing: -0.5,
                                fontFamily: 'DMSerif',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track and analyze cryptocurrency prices',
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
                  AnimatedBuilder(
                    animation: refreshAnimation,
                    builder: (context, child) {
                      return IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isRefreshing
                                ? (isDark ? Colors.blue[700] : Colors.blue[100])
                                : (isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Transform.rotate(
                            angle: refreshAnimation.value * 2 * 3.14159,
                            child: Icon(
                              Icons.refresh,
                              color: isRefreshing
                                  ? (isDark
                                      ? Colors.blue[300]
                                      : Colors.blue[600])
                                  : (isDark ? Colors.white : Colors.black),
                              size: 20,
                            ),
                          ),
                        ),
                        onPressed: isRefreshing ? null : onRefresh,
                        tooltip:
                            isRefreshing ? 'Refreshing...' : 'Refresh data',
                      );
                    },
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
