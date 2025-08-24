// widgets/analysis/analysis_form.dart
import 'package:bullbearnews/models/crypto_model.dart';
import 'package:flutter/material.dart';

class AnalysisForm extends StatelessWidget {
  final Animation<double> animation;
  final bool isDark;
  final double rsi;
  final String macd;
  final TextEditingController volumeController;
  final bool isLoading;
  final bool isLoadingCoins;
  final List<CryptoModel> availableCoins;
  final List<CryptoModel> filteredCoins;
  final CryptoModel? selectedCoin;
  final bool showCoinDropdown;
  final bool canAnalyze;
  final VoidCallback onAnalyze;
  final Function(double) onRSIChanged;
  final Function(String) onMACDChanged;
  final Function(String) onVolumeChanged;
  final Function(CryptoModel) onCoinSelected;
  final Function(String) onSearchChanged;
  final VoidCallback onToggleDropdown;

  const AnalysisForm({
    super.key,
    required this.animation,
    required this.isDark,
    required this.rsi,
    required this.macd,
    required this.volumeController,
    required this.isLoading,
    required this.isLoadingCoins,
    required this.availableCoins,
    required this.filteredCoins,
    required this.selectedCoin,
    required this.showCoinDropdown,
    required this.canAnalyze,
    required this.onAnalyze,
    required this.onRSIChanged,
    required this.onMACDChanged,
    required this.onVolumeChanged,
    required this.onCoinSelected,
    required this.onSearchChanged,
    required this.onToggleDropdown,
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
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildCoinSelector(),
                  const SizedBox(height: 20),
                  _buildRSISlider(context),
                  const SizedBox(height: 20),
                  _buildMACDSelector(),
                  const SizedBox(height: 20),
                  _buildVolumeInput(),
                  const SizedBox(height: 24),
                  _buildAnalyzeButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
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
          child: const Icon(Icons.analytics_outlined,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Technical Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFDFD0B8)
                      : const Color(0xFF222831),
                  fontFamily: 'DMSerif',
                ),
              ),
              Text(
                'Configure your analysis parameters',
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

  Widget _buildCoinSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Cryptocurrency',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
            fontFamily: 'DMSerif',
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: isLoadingCoins ? null : onToggleDropdown,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF222831).withOpacity(0.5)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF948979).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                if (selectedCoin != null) ...[
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFF948979),
                    child: Text(
                      selectedCoin!.symbol.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedCoin!.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFDFD0B8)
                                : const Color(0xFF222831),
                          ),
                        ),
                        Text(
                          '${selectedCoin!.symbol.toUpperCase()} • \$${selectedCoin!.currentPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF948979),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Text(
                      isLoadingCoins ? 'Loading coins...' : 'Select a coin',
                      style: TextStyle(
                        color: const Color(0xFF948979),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
                if (isLoadingCoins)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF948979),
                      ),
                    ),
                  )
                else
                  Icon(
                    showCoinDropdown
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF948979),
                  ),
              ],
            ),
          ),
        ),
        if (showCoinDropdown && !isLoadingCoins) ...[
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222831) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF948979).withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search coins...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF948979),
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF948979),
                        size: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: const Color(0xFF948979).withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: const Color(0xFF948979).withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF948979),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831),
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredCoins.length,
                    itemBuilder: (context, index) {
                      final coin = filteredCoins[index];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFF948979),
                          child: Text(
                            coin.symbol.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          coin.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFDFD0B8)
                                : const Color(0xFF222831),
                          ),
                        ),
                        subtitle: Text(
                          '${coin.symbol.toUpperCase()} • \$${coin.currentPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF948979),
                          ),
                        ),
                        onTap: () => onCoinSelected(coin),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRSISlider(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RSI Value',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
                fontFamily: 'DMSerif',
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getRSIColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getRSIColor().withOpacity(0.4),
                ),
              ),
              child: Text(
                '${rsi.toInt()} - ${_getRSIStatus()}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _getRSIColor(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _getRSIColor(),
            inactiveTrackColor: _getRSIColor().withOpacity(0.3),
            thumbColor: _getRSIColor(),
            overlayColor: _getRSIColor().withOpacity(0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: rsi,
            min: 0,
            max: 100,
            divisions: 100,
            onChanged: onRSIChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildMACDSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MACD Signal',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
            fontFamily: 'DMSerif',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: ['positive', 'negative', 'neutral'].map((value) {
            final isSelected = macd == value;
            return Expanded(
              child: GestureDetector(
                onTap: () => onMACDChanged(value),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _getMACDColor(value).withOpacity(0.2)
                        : (isDark
                            ? const Color(0xFF222831).withOpacity(0.5)
                            : const Color(0xFFF5F5F5)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _getMACDColor(value)
                          : const Color(0xFF948979).withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    value.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? _getMACDColor(value)
                          : const Color(0xFF948979),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVolumeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Volume',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
            fontFamily: 'DMSerif',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: volumeController,
          onChanged: onVolumeChanged,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter volume (e.g., 10000000)',
            hintStyle: const TextStyle(
              color: Color(0xFF948979),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.trending_up,
              color: Color(0xFF948979),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF948979).withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF948979).withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF948979),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF222831).withOpacity(0.5)
                : const Color(0xFFF5F5F5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: TextStyle(
            color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (isLoading || !canAnalyze) ? null : onAnalyze,
        style: ElevatedButton.styleFrom(
          backgroundColor: canAnalyze
              ? (isLoading
                  ? const Color(0xFF948979).withOpacity(0.7)
                  : const Color(0xFF948979))
              : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: canAnalyze && !isLoading ? 3 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
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
                canAnalyze ? Icons.analytics : Icons.lock,
                color: Colors.white,
                size: 20,
              ),
            if (!isLoading) const SizedBox(width: 8),
            Text(
              isLoading
                  ? 'Analyzing...'
                  : canAnalyze
                      ? 'Analyze Coin'
                      : 'Upgrade Required',
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
  }

  Color _getRSIColor() {
    if (rsi >= 70) return Colors.red;
    if (rsi <= 30) return Colors.green;
    return Colors.orange;
  }

  String _getRSIStatus() {
    if (rsi >= 70) return 'Overbought';
    if (rsi <= 30) return 'Oversold';
    return 'Neutral';
  }

  Color _getMACDColor(String macdValue) {
    final lowerMacd = macdValue.toLowerCase();
    if (lowerMacd.contains('positive') || lowerMacd.contains('positive')) {
      return Colors.green;
    } else if (lowerMacd.contains('negative') ||
        lowerMacd.contains('negative')) {
      return Colors.red;
    }
    return Colors.orange;
  }
}
