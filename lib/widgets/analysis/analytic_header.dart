import 'package:flutter/material.dart';

class AnalyticHeader extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback onRefresh;
  final bool isDark;

  const AnalyticHeader({
    super.key,
    required this.animation,
    required this.onRefresh,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Logo and Title
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
                              child: const Icon(
                                Icons.analytics_rounded,
                                color: Color(0xFFDFD0B8),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'AI Analytics',
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
                          'Smart crypto analysis powered by AI',
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

                  // Action buttons
                  _buildActionButton(
                    icon: Icons.refresh_rounded,
                    onTap: onRefresh,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF393E46),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
