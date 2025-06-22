import 'package:bullbearnews/widgets/profile/favorite_cryptos_list.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/crypto_model.dart';
import '../../services/crypto_service.dart';

class FavoriteCryptosSection extends StatefulWidget {
  const FavoriteCryptosSection({super.key});

  @override
  State<FavoriteCryptosSection> createState() => _FavoriteCryptosSectionState();
}

class _FavoriteCryptosSectionState extends State<FavoriteCryptosSection> {
  final CryptoService _cryptoService = CryptoService();
  List<CryptoModel> _favoriteCryptos = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadFavoriteCryptos();
  }

  Future<void> _loadFavoriteCryptos() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final List<CryptoModel> allCryptos = await _cryptoService.getCryptoData();
      final prefs = await SharedPreferences.getInstance();
      final List<String> favoriteIds =
          prefs.getStringList('favoriteCryptos') ?? [];

      if (mounted) {
        setState(() {
          _favoriteCryptos = allCryptos
              .where((crypto) => favoriteIds.contains(crypto.id))
              .toList();
          _favoriteCryptos.sort((a, b) => b.marketCap.compareTo(a.marketCap));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred while loading favorites: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return _buildGlassSection(
      title: 'Favorite Cryptos',
      theme: theme,
      isDarkMode: isDarkMode,
      child: Column(
        children: [
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ),
          FavoriteCryptosList(
            isLoading: _isLoading,
            favoriteCryptos: _favoriteCryptos,
            onRefresh: _loadFavoriteCryptos,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassSection({
    required String title,
    required ThemeData theme,
    required bool isDarkMode,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF393E46).withOpacity(0.7)
            : const Color(0xFFF5F5F5).withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? const Color(0xFF393E46).withOpacity(0.3)
              : const Color(0xFFE0E0E0).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? const Color(0xFF222831).withOpacity(0.2)
                : const Color(0xFFDFD0B8).withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDarkMode
                    ? const Color(0xFFDFD0B8)
                    : const Color(0xFF222831),
                letterSpacing: -0.8,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
