import 'package:flutter/material.dart';
import 'package:bullbearnews/models/crypto_model.dart';

class AnalyticsCoinSelector extends StatefulWidget {
  final bool isLoadingCoins;
  final List<CryptoModel> availableCoins;
  final List<CryptoModel> filteredCoins;
  final CryptoModel? selectedCoin;
  final bool showCoinDropdown;
  final bool isDark;
  final Function(CryptoModel) onCoinSelected;
  final Function(String) onSearchChanged;
  final VoidCallback onToggleDropdown; // Yeni callback

  const AnalyticsCoinSelector({
    super.key,
    required this.isLoadingCoins,
    required this.availableCoins,
    required this.filteredCoins,
    required this.selectedCoin,
    required this.showCoinDropdown,
    required this.isDark,
    required this.onCoinSelected,
    required this.onSearchChanged,
    required this.onToggleDropdown, // Yeni parametre
  });

  @override
  State<AnalyticsCoinSelector> createState() => _AnalyticsCoinSelectorState();
}

class _AnalyticsCoinSelectorState extends State<AnalyticsCoinSelector> {
  final TextEditingController _coinSearchController = TextEditingController();

  @override
  void dispose() {
    _coinSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoadingCoins) {
      return _buildLoadingState();
    }

    return Column(
      children: [
        GestureDetector(
          onTap: widget.onToggleDropdown, // Dropdown'u toggle edecek
          child: _buildCoinSelector(),
        ),
        if (widget.showCoinDropdown) ...[
          const SizedBox(height: 8),
          _buildCoinDropdown(),
        ],
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF222831).withOpacity(0.5)
            : const Color(0xFFDFD0B8).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Loading coins...'),
        ],
      ),
    );
  }

  Widget _buildCoinSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF222831).withOpacity(0.5)
            : const Color(0xFFDFD0B8).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (widget.selectedCoin != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.selectedCoin!.image,
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.currency_bitcoin, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.selectedCoin!.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831),
                    ),
                  ),
                  Text(
                    widget.selectedCoin!.symbol.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.isDark
                          ? const Color(0xFF948979)
                          : const Color(0xFF393E46),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Icon(Icons.currency_bitcoin),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Select a cryptocurrency'),
            ),
          ],
          Icon(
            widget.showCoinDropdown
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: widget.isDark
                ? const Color(0xFFDFD0B8)
                : const Color(0xFF222831),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinDropdown() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF222831).withOpacity(0.9)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _coinSearchController,
              decoration: InputDecoration(
                hintText: 'Search coins...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: widget.isDark
                    ? const Color(0xFF393E46).withOpacity(0.5)
                    : const Color(0xFFDFD0B8).withOpacity(0.3),
              ),
              onChanged: widget.onSearchChanged,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.filteredCoins.length,
              itemBuilder: (context, index) {
                final coin = widget.filteredCoins[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      coin.image,
                      width: 32,
                      height: 32,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.currency_bitcoin, size: 32),
                    ),
                  ),
                  title: Text(
                    coin.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: widget.isDark
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831),
                    ),
                  ),
                  subtitle: Text(
                    coin.symbol.toUpperCase(),
                    style: TextStyle(
                      color: widget.isDark
                          ? const Color(0xFF948979)
                          : const Color(0xFF393E46),
                    ),
                  ),
                  trailing: Text(
                    '\$${coin.currentPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: widget.isDark
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831),
                    ),
                  ),
                  onTap: () {
                    widget.onCoinSelected(coin);
                    _coinSearchController.clear();
                    widget.onSearchChanged('');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
