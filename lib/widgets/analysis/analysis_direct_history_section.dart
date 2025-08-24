import 'package:bullbearnews/services/premium_analysis_service.dart';
import 'package:flutter/material.dart';

class AnalysisDirectHistorySection extends StatefulWidget {
  final bool isDark;
  final Animation<double> historyAnimation;
  final VoidCallback? onHistoryUpdated; // Callback ekle

  const AnalysisDirectHistorySection({
    super.key,
    required this.isDark,
    required this.historyAnimation,
    this.onHistoryUpdated, // Optional callback
  });

  @override
  State<AnalysisDirectHistorySection> createState() =>
      _AnalysisDirectHistorySectionState();
}

class _AnalysisDirectHistorySectionState
    extends State<AnalysisDirectHistorySection> {
  List<AnalysisHistoryItem> analysisHistory = [];
  bool isLoading = true;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final history = await PremiumAnalysisService.getAnalysisHistory();
      if (mounted) {
        setState(() {
          analysisHistory = history;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading history: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _refreshHistory() async {
    if (mounted) {
      setState(() => isRefreshing = true);
    }

    try {
      // Firebase'den fresh data al
      await PremiumAnalysisService.refreshHistoryFromFirebase();
      final history = await PremiumAnalysisService.getAnalysisHistory();

      if (mounted) {
        setState(() {
          analysisHistory = history;
          isRefreshing = false;
        });
        // Parent'a değişikliği bildir
        widget.onHistoryUpdated?.call();
      }
    } catch (e) {
      print('Error refreshing history: $e');
      if (mounted) {
        setState(() => isRefreshing = false);
      }
    }
  }

  Future<void> _deleteSingleItem(String analysisId) async {
    final confirmed = await _showConfirmationDialog(
      'Delete Analysis',
      'Are you sure you want to delete this analysis?',
    );

    if (confirmed == true) {
      try {
        await PremiumAnalysisService.deleteAnalysis(analysisId);
        await _loadHistory(); // Refresh UI

        // Parent'a değişikliği bildir
        widget.onHistoryUpdated?.call();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Analysis deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error deleting analysis: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to delete analysis'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<bool?> _showConfirmationDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              widget.isDark ? const Color(0xFF393E46) : Colors.white,
          title: Text(
            title,
            style: TextStyle(
              color: widget.isDark
                  ? const Color(0xFFDFD0B8)
                  : const Color(0xFF222831),
              fontFamily: 'DMSerif',
            ),
          ),
          content: Text(
            content,
            style: TextStyle(
              color: widget.isDark
                  ? const Color(0xFF948979)
                  : const Color(0xFF393E46),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: widget.isDark
                      ? const Color(0xFF948979)
                      : const Color(0xFF393E46),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshHistory,
      color: const Color(0xFF948979),
      backgroundColor: widget.isDark ? const Color(0xFF393E46) : Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: _buildDirectHistorySection(),
      ),
    );
  }

  Widget _buildDirectHistorySection() {
    return AnimatedBuilder(
      animation: widget.historyAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - widget.historyAnimation.value)),
          child: Opacity(
            opacity: widget.historyAnimation.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Loading state
                if (isLoading)
                  _buildLoadingState()
                // Empty state
                else if (analysisHistory.isEmpty)
                  _buildEmptyState()
                // History items
                else
                  Column(
                    children: analysisHistory.map<Widget>((item) {
                      final style = _calculateDirectStyle(item.analysis);
                      return _buildHistoryItem(item, style);
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF393E46).withOpacity(0.3)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF948979)),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading History...',
            style: TextStyle(
              fontSize: 16,
              color: widget.isDark
                  ? const Color(0xFF948979)
                  : const Color(0xFF393E46),
              fontFamily: 'DMSerif',
            ),
          ),
        ],
      ),
    );
  }

  // Direkt skorlama fonksiyonu (aynı mantık)
  Map<String, dynamic> _calculateDirectStyle(String analysisText) {
    final lower = analysisText.toLowerCase();

    print('📊 DIRECT SCORING START');
    print(
        'Text preview: ${lower.length > 100 ? "${lower.substring(0, 100)}..." : lower}');

    // Önce neutral check
    bool isNeutral = lower.contains('market condition: neutral') ||
        lower.contains('1) market condition: neutral') ||
        lower.contains('neutral zone');

    print('Neutral check: $isNeutral');

    if (isNeutral) {
      print('🟠 DIRECT: NEUTRAL DETECTED');
      return {
        'color': Colors.orange,
        'icon': Icons.warning_rounded,
        'sentiment': 'NEUTRAL'
      };
    }

    // Skorlama
    int bull = 0, bear = 0, neutral = 0;

    // Bearish patterns
    if (lower.contains('bearish')) bear += 5;
    if (lower.contains('sell')) bear += 4;
    if (lower.contains('negative')) bear += 3;
    if (lower.contains('downtrend')) bear += 3;
    if (lower.contains('overbought')) bear += 2;
    if (lower.contains('caution')) bear += 1;

    // Bullish patterns
    if (lower.contains('bullish')) {
      if (lower.contains('slight bullish') || lower.contains('bullish bias')) {
        bull += 2;
      } else {
        bull += 5;
      }
    }
    if (lower.contains('buy')) bull += 4;
    if (lower.contains('positive')) bull += 3;
    if (lower.contains('uptrend')) bull += 3;
    if (lower.contains('support')) bull += 2;
    if (lower.contains('oversold')) bull += 2;

    // Neutral patterns
    if (lower.contains('neutral')) neutral += 6;
    if (lower.contains('sideways')) neutral += 4;
    if (lower.contains('range')) neutral += 3;
    if (lower.contains('hold')) neutral += 3;
    if (lower.contains('wait')) neutral += 2;
    if (lower.contains('lack of strong')) neutral += 2;

    print('📊 SCORES: Bull=$bull, Bear=$bear, Neutral=$neutral');

    if (neutral >= bull && neutral >= bear && neutral > 0) {
      print('🟠 DIRECT: NEUTRAL WINS');
      return {
        'color': Colors.orange,
        'icon': Icons.warning_rounded,
        'sentiment': 'NEUTRAL'
      };
    } else if (bear > bull && bear > neutral) {
      print('🔴 DIRECT: BEARISH WINS');
      return {
        'color': Colors.red,
        'icon': Icons.trending_down_rounded,
        'sentiment': 'BEARISH'
      };
    } else if (bull > bear && bull > neutral) {
      print('🟢 DIRECT: BULLISH WINS');
      return {
        'color': Colors.green,
        'icon': Icons.trending_up_rounded,
        'sentiment': 'BULLISH'
      };
    } else {
      print('🟠 DIRECT: TIE -> NEUTRAL');
      return {
        'color': Colors.orange,
        'icon': Icons.warning_rounded,
        'sentiment': 'NEUTRAL'
      };
    }
  }

  Widget _buildHistoryItem(
      AnalysisHistoryItem item, Map<String, dynamic> style) {
    final cardColor = style['color'] as Color;
    final icon = style['icon'] as IconData;
    final sentiment = style['sentiment'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF393E46).withOpacity(0.5)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withOpacity(0.3), width: 1),
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
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.coinName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831),
                      fontFamily: 'DMSerif',
                    ),
                  ),
                  if (item.coinSymbol != 'UNKNOWN' &&
                      item.coinSymbol != 'LEGACY')
                    Text(
                      item.coinSymbol,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDark
                            ? const Color(0xFF948979)
                            : const Color(0xFF393E46),
                        fontFamily: 'DMSerif',
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _formatHistoryTimestamp(item.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isDark
                        ? const Color(0xFF948979)
                        : const Color(0xFF393E46),
                    fontFamily: 'DMSerif',
                  ),
                ),
                if (item.price > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: cardColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.analysis,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: widget.isDark
                    ? const Color(0xFF948979)
                    : const Color(0xFF393E46),
                height: 1.4,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: widget.isDark
                ? const Color(0xFF948979)
                : const Color(0xFF393E46),
            size: 20,
          ),
          onPressed: () => _deleteSingleItem(item.id),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? const Color(0xFF222831).withOpacity(0.3)
                  : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.technicalData.isNotEmpty) ...[
                  Text(
                    'Technical Data:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: item.technicalData.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: TextStyle(
                            fontSize: 10,
                            color: cardColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  item.analysis,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isDark
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
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF393E46).withOpacity(0.3)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: widget.isDark
                ? const Color(0xFF948979)
                : const Color(0xFF393E46),
          ),
          const SizedBox(height: 16),
          Text(
            'No Analysis History',
            style: TextStyle(
              fontSize: 18,
              color: widget.isDark
                  ? const Color(0xFFDFD0B8)
                  : const Color(0xFF222831),
              fontWeight: FontWeight.w700,
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your AI analysis results will appear here',
            style: TextStyle(
              fontSize: 14,
              color: widget.isDark
                  ? const Color(0xFF948979)
                  : const Color(0xFF393E46),
              fontFamily: 'DMSerif',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatHistoryTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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
}
