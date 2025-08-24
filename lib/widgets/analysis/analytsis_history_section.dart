import 'package:flutter/material.dart';

class AnalyticsHistorySection extends StatelessWidget {
  final Animation<double> animation;
  final List<Map<String, dynamic>> analysisHistory;
  final bool isDark;
  final VoidCallback onClearHistory;
  final Function(int) onDeleteSingleItem;

  const AnalyticsHistorySection({
    super.key,
    required this.animation,
    required this.analysisHistory,
    required this.isDark,
    required this.onClearHistory,
    required this.onDeleteSingleItem,
  });

  // Dinamik icon ve renk belirleme fonksiyonu
  Map<String, dynamic> _getAnalysisStyle(String analysisText) {
    final analysisLower = analysisText.toLowerCase();

    // Skorlama sistemi - her kelime için puan ver
    int bullishScore = 0;
    int bearishScore = 0;
    int neutralScore = 0;

    // Güçlü bearish sinyaller (yüksek puan)
    if (analysisLower.contains('bearish')) bearishScore += 3;
    if (analysisLower.contains('sell')) bearishScore += 3;
    if (analysisLower.contains('negative')) bearishScore += 2;
    if (analysisLower.contains('downtrend')) bearishScore += 2;
    if (analysisLower.contains('decline')) bearishScore += 2;
    if (analysisLower.contains('resistance')) bearishScore += 2;
    if (analysisLower.contains('overbought')) bearishScore += 2;
    if (analysisLower.contains('correction')) bearishScore += 2;
    if (analysisLower.contains('caution')) bearishScore += 1;
    if (analysisLower.contains('risk')) bearishScore += 1;

    // Güçlü bullish sinyaller (yüksek puan)
    if (analysisLower.contains('bullish')) bullishScore += 3;
    if (analysisLower.contains('buy')) bullishScore += 3;
    if (analysisLower.contains('positive')) bullishScore += 2;
    if (analysisLower.contains('uptrend')) bullishScore += 2;
    if (analysisLower.contains('support')) bullishScore += 2;
    if (analysisLower.contains('oversold')) bullishScore += 2;
    if (analysisLower.contains('accumulate')) bullishScore += 2;
    if (analysisLower.contains('opportunity')) bullishScore += 1;

    // Neutral sinyaller
    if (analysisLower.contains('neutral')) neutralScore += 3;
    if (analysisLower.contains('sideways')) neutralScore += 2;
    if (analysisLower.contains('range')) neutralScore += 2;
    if (analysisLower.contains('consolidation')) neutralScore += 2;
    if (analysisLower.contains('hold')) neutralScore += 2;
    if (analysisLower.contains('wait')) neutralScore += 1;
    if (analysisLower.contains('mixed')) neutralScore += 1;

    // En yüksek skora göre karar ver
    if (bearishScore > bullishScore && bearishScore > neutralScore) {
      return {
        'color': Colors.red,
        'icon': Icons.trending_down_rounded,
        'sentiment': 'BEARISH'
      };
    } else if (bullishScore > bearishScore && bullishScore > neutralScore) {
      return {
        'color': Colors.green,
        'icon': Icons.trending_up_rounded,
        'sentiment': 'BULLISH'
      };
    } else if (neutralScore > 0 || (bearishScore == bullishScore)) {
      return {
        'color': Colors.orange,
        'icon': Icons.warning_rounded,
        'sentiment': 'NEUTRAL'
      };
    } else {
      // Hiçbir güçlü sinyal yoksa, ilk kelimeye bak
      if (analysisLower.startsWith('bearish') ||
          analysisLower.contains('market condition: bearish') ||
          analysisLower.contains('1) market condition: bearish')) {
        return {
          'color': Colors.red,
          'icon': Icons.trending_down_rounded,
          'sentiment': 'BEARISH'
        };
      } else {
        return {
          'color': const Color(0xFF948979),
          'icon': Icons.show_chart,
          'sentiment': 'ANALYSIS'
        };
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Analysis History',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFDFD0B8)
                                  : const Color(0xFF222831),
                              fontFamily: 'DMSerif',
                            ),
                          ),
                          if (analysisHistory.isNotEmpty)
                            Text(
                              '${analysisHistory.length} analysis results',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF948979)
                                    : const Color(0xFF393E46),
                                fontFamily: 'DMSerif',
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_sharp,
                        color: isDark
                            ? const Color(0xFF948979)
                            : const Color(0xFF393E46),
                      ),
                      onPressed: analysisHistory.isNotEmpty
                          ? () => _showClearHistoryDialog(context)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                analysisHistory.isEmpty
                    ? _buildEmptyState(isDark)
                    : _buildHistoryList(context, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showClearHistoryDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Clear History',
            style: TextStyle(
              color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
              fontFamily: 'DMSerif',
            ),
          ),
          content: Text(
            'Are you sure you want to clear all analysis history? This action cannot be undone.',
            style: TextStyle(
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
            ),
          ),
          backgroundColor:
              isDark ? const Color(0xFF393E46) : const Color(0xFFDFD0B8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFDFD0B8)
                      : const Color(0xFF222831),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Clear All'),
              onPressed: () {
                onClearHistory();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF393E46).withOpacity(0.3)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF948979).withOpacity(0.2)
              : const Color(0xFF393E46).withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF948979).withOpacity(0.1)
                  : const Color(0xFF393E46).withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 48,
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Analysis History',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your AI analysis results will appear here\nafter you perform your first analysis',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              fontFamily: 'DMSerif',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, bool isDark) {
    return Column(
      children: analysisHistory.asMap().entries.map<Widget>((entry) {
        final index = entry.key;
        final item = entry.value;

        final text = item['text'] as String;
        final coinName = item['coin'] as String? ?? 'Unknown';
        final timestamp =
            item['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;

        // Debug: Analiz metnini yazdır
        print('=== PROCESSING HISTORY ITEM $index ===');
        print(
            'Original text: ${text.length > 100 ? "${text.substring(0, 100)}..." : text}');

        final analysisStyle = _getAnalysisStyle(text);
        print(
            'FINAL RESULT: ${analysisStyle['sentiment']} - ${analysisStyle['color']}');
        print('=== END ITEM $index ===\n');

        final cardColor = analysisStyle['color'] as Color;
        final icon = analysisStyle['icon'] as IconData;
        final sentiment = analysisStyle['sentiment'] as String;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF393E46).withOpacity(0.5)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cardColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.all(16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: cardColor.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        coinName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFDFD0B8)
                              : const Color(0xFF222831),
                          fontFamily: 'DMSerif',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        sentiment,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: cardColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF948979)
                        : const Color(0xFF393E46),
                    fontFamily: 'DMSerif',
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFF948979)
                      : const Color(0xFF393E46),
                  height: 1.4,
                ),
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
                size: 20,
              ),
              onPressed: () => _showDeleteConfirmationDialog(context, index),
              tooltip: 'Delete this analysis',
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF222831).withOpacity(0.3)
                      : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Full Analysis:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                        fontFamily: 'DMSerif',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFF948979)
                            : const Color(0xFF393E46),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Analysis',
            style: TextStyle(
              color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
              fontFamily: 'DMSerif',
            ),
          ),
          content: Text(
            'Are you sure you want to delete this analysis?',
            style: TextStyle(
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
            ),
          ),
          backgroundColor:
              isDark ? const Color(0xFF393E46) : const Color(0xFFDFD0B8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFDFD0B8)
                      : const Color(0xFF222831),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
              onPressed: () {
                onDeleteSingleItem(index);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text('Analysis deleted successfully'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
