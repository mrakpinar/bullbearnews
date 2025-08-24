import 'dart:async';

import 'package:bullbearnews/services/firebase_favorites_service.dart';
import 'package:bullbearnews/widgets/profile/favorite_cryptos_list.dart';
import 'package:flutter/material.dart';
import '../../models/crypto_model.dart';
import '../../services/crypto_service.dart';
import '../../constants/colors.dart';

class FavoriteCryptosSection extends StatefulWidget {
  const FavoriteCryptosSection({super.key});

  @override
  State<FavoriteCryptosSection> createState() => _FavoriteCryptosSectionState();
}

class _FavoriteCryptosSectionState extends State<FavoriteCryptosSection>
    with SingleTickerProviderStateMixin {
  final CryptoService _cryptoService = CryptoService();
  final FirebaseFavoritesService _favoritesService = FirebaseFavoritesService();

  List<CryptoModel> _favoriteCryptos = [];
  bool _isLoading = true;
  String _errorMessage = '';
  StreamSubscription<Set<String>>? _favoritesSubscription;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadFavoriteCryptos();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteCryptos() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      _favoritesSubscription?.cancel();
      _favoritesSubscription = _favoritesService.watchFavoriteCryptos().listen(
        (favoriteIds) async {
          if (favoriteIds.isEmpty) {
            if (mounted) {
              setState(() {
                _favoriteCryptos = [];
                _isLoading = false;
                _errorMessage = '';
              });
            }
            return;
          }

          try {
            final List<CryptoModel> allCryptos =
                await _cryptoService.getCryptoData();
            final List<CryptoModel> favoriteCryptos = allCryptos
                .where((crypto) => favoriteIds.contains(crypto.id))
                .toList();

            for (var crypto in favoriteCryptos) {
              crypto.isFavorite = true;
            }

            favoriteCryptos.sort((a, b) => b.marketCap.compareTo(a.marketCap));

            if (mounted) {
              setState(() {
                _favoriteCryptos = favoriteCryptos;
                _isLoading = false;
                _errorMessage = '';
              });
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _errorMessage = 'Failed to load crypto data: $e';
                _isLoading = false;
              });
            }
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to load favorites: $error';
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred while loading favorites: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRemoveFavorite(CryptoModel crypto) async {
    try {
      await _favoritesService.removeFavoriteCrypto(crypto.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('${crypto.name} removed from favorites')),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to remove favorite: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildModernSection(
        title: 'Favorite Cryptos',
        isDark: isDark,
        child: Column(
          children: [
            if (_errorMessage.isNotEmpty)
              _buildErrorCard(isDark)
            else if (_isLoading)
              _buildLoadingCard(isDark)
            else if (_favoriteCryptos.isEmpty)
              _buildEmptyStateCard(isDark)
            else
              FavoriteCryptosList(
                isLoading: _isLoading,
                favoriteCryptos: _favoriteCryptos,
                onRefresh: _loadFavoriteCryptos,
                onRemoveFavorite: _handleRemoveFavorite,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSection({
    required String title,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.lightText.withOpacity(0.1)
              : AppColors.darkText.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withOpacity(0.6),
                  Colors.red.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? AppColors.lightText : AppColors.darkText,
                          fontFamily: 'DMSerif',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Synced across all your devices',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.lightText.withOpacity(0.6)
                              : AppColors.darkText.withOpacity(0.6),
                          fontFamily: 'DMSerif',
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isLoading)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _loadFavoriteCryptos,
                      tooltip: 'Refresh',
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade600,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to Load Favorites',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade500,
              fontFamily: 'DMSerif',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadFavoriteCryptos,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: AppColors.secondary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading your favorite cryptos...',
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppColors.lightText.withOpacity(0.7)
                    : AppColors.darkText.withOpacity(0.7),
                fontFamily: 'DMSerif',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Syncing from cloud storage',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.lightText.withOpacity(0.5)
                    : AppColors.darkText.withOpacity(0.5),
                fontFamily: 'DMSerif',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.star_border_rounded,
              color: Colors.red,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Favorite Cryptos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.lightText : AppColors.darkText,
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding cryptocurrencies to your favorites\nto see them here',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.lightText.withOpacity(0.7)
                  : AppColors.darkText.withOpacity(0.7),
              fontFamily: 'DMSerif',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
