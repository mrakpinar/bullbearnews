import 'package:flutter/material.dart';
import 'package:bullbearnews/models/crypto_model.dart';
import 'package:bullbearnews/widgets/analysis/analytics_coin_selector.dart';

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

  bool get _isVolumeValid =>
      double.tryParse(volumeController.text) != null &&
      double.parse(volumeController.text) > 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF393E46).withOpacity(0.8)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coin Selection Section
                  _buildSectionTitle('Select Cryptocurrency', isDark),
                  const SizedBox(height: 12),
                  _buildCoinSelector(),

                  const SizedBox(height: 20),

                  // RSI Section
                  _buildSectionTitle('RSI Value', isDark),
                  const SizedBox(height: 12),
                  _buildRSISection(context),

                  const SizedBox(height: 20),

                  // MACD Section
                  _buildSectionTitle('MACD Direction', isDark),
                  const SizedBox(height: 12),
                  _buildMACDSection(),

                  const SizedBox(height: 20),

                  // Volume Section
                  _buildSectionTitle('Volume', isDark),
                  const SizedBox(height: 12),
                  _buildVolumeSection(),

                  const SizedBox(height: 24),

                  // Analyze Button
                  _buildAnalyzeButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
        fontFamily: 'DMSerif',
      ),
    );
  }

  Widget _buildCoinSelector() {
    return AnalyticsCoinSelector(
      isLoadingCoins: isLoadingCoins,
      availableCoins: availableCoins,
      filteredCoins: filteredCoins,
      selectedCoin: selectedCoin,
      showCoinDropdown: showCoinDropdown,
      isDark: isDark,
      onCoinSelected: onCoinSelected,
      onSearchChanged: onSearchChanged,
      onToggleDropdown: onToggleDropdown,
    );
  }

  Widget _buildRSISection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF222831).withOpacity(0.5)
            : const Color(0xFFDFD0B8).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current: ${rsi.round()}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFDFD0B8)
                      : const Color(0xFF222831),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getRSIColor(rsi),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getRSIStatus(rsi),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF948979),
              inactiveTrackColor: const Color(0xFF948979).withOpacity(0.3),
              thumbColor: const Color(0xFF393E46),
              overlayColor: const Color(0xFF393E46).withOpacity(0.2),
              valueIndicatorColor: const Color(0xFF393E46),
              valueIndicatorTextStyle: const TextStyle(
                color: Color(0xFFDFD0B8),
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Slider(
              value: rsi,
              min: 0,
              max: 100,
              divisions: 100,
              label: rsi.round().toString(),
              onChanged: onRSIChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMACDSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF222831).withOpacity(0.5)
            : const Color(0xFFDFD0B8).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: macd,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
          ),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
          ),
          items: [
            DropdownMenuItem(
              value: 'pozitif',
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text('Pozitif'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'negatif',
              child: Row(
                children: [
                  Icon(
                    Icons.trending_down_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text('Negatif'),
                ],
              ),
            ),
          ],
          onChanged: (newValue) {
            if (newValue != null) {
              onMACDChanged(newValue);
            }
          },
        ),
      ),
    );
  }

  Widget _buildVolumeSection() {
    return TextField(
      controller: volumeController,
      keyboardType: TextInputType.number,
      style: TextStyle(
        color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: "Enter volume (e.g., 184000000.0)",
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
        ),
        prefixIcon: Icon(
          Icons.bar_chart_rounded,
          color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
        ),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF222831).withOpacity(0.5)
            : const Color(0xFFDFD0B8).withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorText: volumeController.text.isEmpty
            ? null
            : (_isVolumeValid ? null : 'Please enter a valid number'),
        errorStyle: const TextStyle(color: Colors.red),
      ),
      onChanged: onVolumeChanged,
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canAnalyze ? onAnalyze : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canAnalyze ? const Color(0xFF393E46) : Colors.grey,
          foregroundColor: const Color(0xFFDFD0B8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFFDFD0B8),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome_rounded),
                  const SizedBox(width: 8),
                  Text(
                    selectedCoin != null
                        ? 'Analyze ${selectedCoin!.symbol.toUpperCase()}'
                        : 'Select a coin first',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Color _getRSIColor(double rsi) {
    if (rsi >= 70) return Colors.red;
    if (rsi <= 30) return Colors.green;
    return Colors.orange;
  }

  String _getRSIStatus(double rsi) {
    if (rsi >= 70) return 'Overbought';
    if (rsi <= 30) return 'Oversold';
    return 'Neutral';
  }
}
