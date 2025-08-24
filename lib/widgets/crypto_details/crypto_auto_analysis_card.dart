// widgets/crypto_details/crypto_auto_analysis_card.dart
// widgets/crypto_details/crypto_auto_analysis_card.dart
import 'package:bullbearnews/widgets/premium/premium_widgets.dart';
import 'package:flutter/material.dart';
import '../../../models/crypto_model.dart';
import '../../../services/auto_analysis_service.dart';
import '../../../services/premium_analysis_service.dart';

class CryptoAutoAnalysisCard extends StatefulWidget {
  final CryptoModel crypto;

  const CryptoAutoAnalysisCard({
    super.key,
    required this.crypto,
  });

  @override
  State<CryptoAutoAnalysisCard> createState() => _CryptoAutoAnalysisCardState();
}

class _CryptoAutoAnalysisCardState extends State<CryptoAutoAnalysisCard>
    with TickerProviderStateMixin {
  bool _isAnalyzing = false;
  String? _lastAnalysis;
  Map<String, dynamic>? _technicalData;
  DateTime? _lastAnalysisTime;
  bool _isPremium = false;
  int _remainingAnalyses = 0;
  int _todayAnalysisCount = 0;
  List<AnalysisHistoryItem> _analysisHistory = [];
  bool _showHistory = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _resultController;
  late Animation<double> _resultAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPremiumStatus();
    _loadAnalysisHistory();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _resultController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _resultAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.easeOut),
    );
  }

  Future<void> _loadPremiumStatus() async {
    final isPremium = await PremiumAnalysisService.isPremiumUser();
    final remaining = await PremiumAnalysisService.getRemainingAnalyses();
    final todayCount = await PremiumAnalysisService.getTodayAnalysisCount();

    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _remainingAnalyses = remaining;
        _todayAnalysisCount = todayCount;
      });
    }
  }

  Future<void> _loadAnalysisHistory() async {
    final history = await PremiumAnalysisService.getAnalysisHistory();
    if (mounted) {
      setState(() {
        _analysisHistory = history;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _performAutoAnalysis() async {
    // Premium kontrolü
    final canAnalyze = await PremiumAnalysisService.canMakeAnalysis();
    if (!canAnalyze) {
      _showPremiumDialog();
      return;
    }

    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _lastAnalysis = null;
    });

    _pulseController.repeat(reverse: true);

    try {
      // Progress mesajları
      _showProgress('📊 Fetching price data...');
      await Future.delayed(const Duration(milliseconds: 800));

      _showProgress('📈 Calculating technical indicators...');
      await Future.delayed(const Duration(milliseconds: 1000));

      _showProgress('🤖 Generating AI analysis...');

      final result = await AutoAnalysisService.performCompleteAnalysis(
        symbol: widget.crypto.symbol,
        coinName: widget.crypto.name,
        currentPrice: widget.crypto.currentPrice,
      );

      if (result != null && mounted) {
        setState(() {
          _lastAnalysis = result['analysis'];
          _technicalData = result['technicalData'];
          _lastAnalysisTime = DateTime.now();
        });

        // Analiz sayacını artır (premium olmayan kullanıcılar için)
        if (!_isPremium) {
          await PremiumAnalysisService.incrementAnalysisCount();
        }

        // Analizi history'ye kaydet
        final historyItem = AnalysisHistoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          coinName: widget.crypto.name,
          coinSymbol: widget.crypto.symbol,
          price: widget.crypto.currentPrice,
          analysis: result['analysis'],
          technicalData: result['technicalData'],
          timestamp: DateTime.now(),
        );

        await PremiumAnalysisService.saveAnalysisToHistory(historyItem);
        await _loadAnalysisHistory();
        await _loadPremiumStatus(); // Status'u güncelle

        _pulseController.stop();
        _resultController.forward();

        _showSnackBar('✅ Analysis completed and saved!', isSuccess: true);
      } else {
        _showSnackBar('❌ Analysis failed. Please try again.', isError: true);
      }
    } catch (e) {
      _showSnackBar('❌ Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        _pulseController.stop();
      }
    }
  }

  void _showPremiumDialog() {
    PremiumWidgets.showPremiumDialog(
      context: context,
      remainingAnalyses: _remainingAnalyses,
      todayAnalysisCount: _todayAnalysisCount,
    ).then((_) {
      // Dialog kapatıldıktan sonra status'u güncelle
      _loadPremiumStatus();
    });
  }

  void _showProgress(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 800),
          backgroundColor: const Color(0xFF948979),
        ),
      );
    }
  }

  void _showSnackBar(String message,
      {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline
                  : isSuccess
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError
            ? Colors.red.shade600
            : isSuccess
                ? Colors.green.shade600
                : const Color(0xFF948979),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF393E46) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF948979).withOpacity(0.2)
              : const Color(0xFFE0E0E0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 16),
            _buildStatusInfo(isDark),
            const SizedBox(height: 16),
            // Premium limit warning (sadece free kullanıcılar için)
            if (!_isPremium && _remainingAnalyses <= 0)
              PremiumWidgets.buildLimitWarningCard(
                isDark: isDark,
                todayAnalysisCount: _todayAnalysisCount,
                remainingAnalyses: _remainingAnalyses,
                onUpgrade: _showPremiumDialog,
              ),
            const SizedBox(height: 4),
            _buildAnalysisButton(isDark),
            if (_technicalData != null) ...[
              const SizedBox(height: 20),
              _buildTechnicalIndicators(isDark),
            ],
            if (_lastAnalysis != null) ...[
              const SizedBox(height: 20),
              _buildAnalysisResult(isDark),
            ],
            if (_analysisHistory.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildHistorySection(isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF393E46), Color(0xFF948979)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.psychology_outlined,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'AI Technical Analysis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831),
                      fontFamily: 'DMSerif',
                    ),
                  ),
                  if (_isPremium) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.orange, Colors.deepOrange],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'PREMIUM',
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
              Text(
                'Automatic analysis with 7+ indicators',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF948979),
                  fontFamily: 'DMSerif',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF222831).withOpacity(0.5)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analysis History',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF948979),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${_analysisHistory.length} analyses',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFDFD0B8)
                      : const Color(0xFF222831),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _isPremium ? 'Unlimited' : 'Daily Limit',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF948979),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _isPremium ? '∞' : '$_remainingAnalyses left',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _isPremium
                      ? Colors.orange
                      : (_remainingAnalyses > 0 ? Colors.green : Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisButton(bool isDark) {
    final canAnalyze = _isPremium || _remainingAnalyses > 0;

    return SizedBox(
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isAnalyzing ? _pulseAnimation.value : 1.0,
            child: ElevatedButton(
              onPressed:
                  (_isAnalyzing || !canAnalyze) ? null : _performAutoAnalysis,
              style: ElevatedButton.styleFrom(
                backgroundColor: canAnalyze
                    ? (_isAnalyzing
                        ? const Color(0xFF948979).withOpacity(0.7)
                        : const Color(0xFF948979))
                    : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: _isAnalyzing ? 8 : 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isAnalyzing)
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(right: 12),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    Icon(
                      canAnalyze ? Icons.auto_awesome : Icons.lock,
                      color: Colors.white,
                      size: 20,
                    ),
                  if (!_isAnalyzing) const SizedBox(width: 8),
                  Text(
                    _isAnalyzing
                        ? 'Analyzing...'
                        : canAnalyze
                            ? 'Start Auto Analysis'
                            : 'Premium Required',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'DMSerif',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistorySection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF222831).withOpacity(0.5)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showHistory = !_showHistory;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    color: const Color(0xFF948979),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Analysis History (${_analysisHistory.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                        fontFamily: 'DMSerif',
                      ),
                    ),
                  ),
                  Icon(
                    _showHistory ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF948979),
                  ),
                ],
              ),
            ),
          ),
          if (_showHistory) ...[
            const Divider(height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _analysisHistory.take(5).length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _analysisHistory[index];
                  return _buildHistoryItem(item, isDark);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryItem(AnalysisHistoryItem item, bool isDark) {
    return InkWell(
      onTap: () {
        setState(() {
          _lastAnalysis = item.analysis;
          _technicalData = item.technicalData;
          _lastAnalysisTime = item.timestamp;
        });
        _resultController.forward();
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF948979),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.coinName} (${item.coinSymbol.toUpperCase()})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831),
                    ),
                  ),
                  Text(
                    'Price: ${item.price.toStringAsFixed(2)} • ${_formatTimeAgo(item.timestamp)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF948979),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalIndicators(bool isDark) {
    if (_technicalData == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF222831).withOpacity(0.5)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Technical Indicators',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _buildIndicatorCard(
                  'RSI', _technicalData!['rsi']?.toString() ?? 'N/A', isDark),
              _buildIndicatorCard(
                  'MACD', _technicalData!['macd']?.toString() ?? 'N/A', isDark),
              _buildIndicatorCard(
                  'BB Status',
                  _technicalData!['bollingerBands']?.toString() ?? 'N/A',
                  isDark),
              _buildIndicatorCard('Volume',
                  _technicalData!['volumeTrend']?.toString() ?? 'N/A', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorCard(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF393E46).withOpacity(0.5)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF948979).withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF948979),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult(bool isDark) {
    return AnimatedBuilder(
      animation: _resultAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _resultAnimation.value)),
          child: Opacity(
            opacity: _resultAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF948979).withOpacity(0.1),
                    const Color(0xFF393E46).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF948979).withOpacity(0.3),
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
                          color: const Color(0xFF948979),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AI Analysis Result',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFDFD0B8)
                                : const Color(0xFF222831),
                            fontFamily: 'DMSerif',
                          ),
                        ),
                      ),
                      if (_lastAnalysisTime != null)
                        Text(
                          _formatTimeAgo(_lastAnalysisTime!),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF948979),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF222831).withOpacity(0.3)
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _lastAnalysis!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                        height: 1.6,
                        fontFamily: 'DMSerif',
                      ),
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

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
