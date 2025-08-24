import 'package:flutter/material.dart';

enum SortOption {
  marketCapDesc,
  priceDesc,
  priceAsc,
  changeDesc,
  changeAsc,
  favoritesFirst,
}

class MarketSortChips extends StatelessWidget {
  final SortOption currentSortOption;
  final Function(SortOption) onSortChanged;
  final bool isDarkMode;

  const MarketSortChips({
    super.key,
    required this.currentSortOption,
    required this.onSortChanged,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _buildSortChip(context, 'Market Cap', SortOption.marketCapDesc),
          _buildSortChip(context, 'Highest Price', SortOption.priceDesc),
          _buildSortChip(context, 'Lowest price', SortOption.priceAsc),
          _buildSortChip(context, 'Most Increased', SortOption.changeDesc),
          _buildSortChip(context, 'Most Decreased', SortOption.changeAsc),
          _buildSortChip(context, 'Favorites First', SortOption.favoritesFirst),
        ],
      ),
    );
  }

  Widget _buildSortChip(BuildContext context, String label, SortOption option) {
    final isSelected = currentSortOption == option;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSortChanged(option),
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF393E46),
                        const Color(0xFF948979),
                      ],
                    )
                  : null,
              color: !isSelected
                  ? (isDarkMode
                      ? const Color(0xFF393E46).withOpacity(0.3)
                      : Colors.white.withOpacity(0.7))
                  : null,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : (isDarkMode
                        ? const Color(0xFF948979).withOpacity(0.3)
                        : const Color(0xFF393E46).withOpacity(0.2)),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFDFD0B8)
                    : (isDarkMode
                        ? const Color(0xFF948979)
                        : const Color(0xFF393E46)),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
                fontFamily: 'DMSerif',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
