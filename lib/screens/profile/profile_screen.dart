import 'dart:async';

import 'package:bullbearnews/screens/profile/wallet/wallets_screen.dart';
import 'package:bullbearnews/services/auth_service.dart';
import 'package:bullbearnews/services/firebase_favorites_service.dart';
import 'package:bullbearnews/services/firebase_new_saved_service.dart';
import 'package:bullbearnews/widgets/profile/favorite_cryptos_section.dart';
import 'package:bullbearnews/widgets/profile/liked_portfolios_section.dart';
import 'package:bullbearnews/widgets/profile/portfolio_distribution.dart';
import 'package:bullbearnews/widgets/profile/portfolio_summary.dart';
import 'package:bullbearnews/widgets/profile/profile_drawer.dart';
import 'package:bullbearnews/widgets/profile/profile_header.dart';
import 'package:bullbearnews/widgets/profile/saved_news_section.dart';
import 'package:bullbearnews/widgets/profile/shared_portfolios_section.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../models/crypto_model.dart';
import '../../models/wallet_model.dart';
import '../../services/crypto_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final CryptoService _cryptoService = CryptoService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<CryptoModel> _favoriteCryptos = [];
  List<WalletItem> _walletItems = [];
  bool _isWalletLoading = true;
  String _errorMessage = '';
  double _totalPortfolioValue = 0;
  double _totalInvestment = 0;
  double _totalProfitLoss = 0;
  double _totalProfitLossPercentage = 0;
  String? _profileImageUrl;
  List<Map<String, dynamic>> _mySharedPortfolios = [];
  bool _isLoadingSharedPortfolios = true;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFavoritesService _favoritesService = FirebaseFavoritesService();
  StreamSubscription<Set<String>>? _favoritesSubscription;
  final FirebaseSavedNewsService _savedNewsService = FirebaseSavedNewsService();
  StreamSubscription<int>? _savedNewsCountSubscription;

  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _hideAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _hideAnimation;

  bool _isHeaderVisible = true;
  double _lastScrollOffset = 0;
  static const double _scrollThreshold = 50.0;

  // Favori coin sayısını takip etmek için
  int _favoriteCryptosCount = 0;

  // Saved news sayısını takip etmek için
  int _savedNewsCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
    _loadData();
    _loadMySharedPortfolios();
    _loadWalletItems();
    _setupFavoritesListener();
    _setupSavedNewsListener();
  }

  void _setupSavedNewsListener() {
    _savedNewsCountSubscription =
        _savedNewsService.getSavedNewsCountStream().listen(
      // ignore: avoid_types_as_parameter_names
      (count) {
        if (mounted) {
          setState(() {
            _savedNewsCount = count;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _savedNewsCount = 0;
            _errorMessage = 'Failed to load saved news count: $error';
          });
        }
      },
    );
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _hideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _headerAnimationController, curve: Curves.easeOut),
    );
    _hideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _hideAnimationController, curve: Curves.easeInOut),
    );

    _headerAnimationController.forward();
    _hideAnimationController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final currentScrollOffset = _scrollController.offset;
      final scrollDelta = currentScrollOffset - _lastScrollOffset;

      if (scrollDelta > _scrollThreshold && _isHeaderVisible) {
        // Scrolling down - hide header
        setState(() {
          _isHeaderVisible = false;
        });
        _hideAnimationController.reverse();
      } else if (scrollDelta < -_scrollThreshold && !_isHeaderVisible) {
        // Scrolling up - show header
        setState(() {
          _isHeaderVisible = true;
        });
        _hideAnimationController.forward();
      }

      // Update when scroll direction changes significantly
      if (scrollDelta.abs() > _scrollThreshold) {
        _lastScrollOffset = currentScrollOffset;
      }
    });
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    _scrollController.dispose();
    _headerAnimationController.dispose();
    _hideAnimationController.dispose();
    _savedNewsCountSubscription?.cancel();
    super.dispose();
  }

  void _setupFavoritesListener() {
    _favoritesSubscription = _favoritesService.watchFavoriteCryptos().listen(
      (favoriteIds) {
        if (mounted) {
          setState(() {
            _favoriteCryptosCount = favoriteIds.length;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _favoriteCryptosCount = 0;
            _errorMessage = 'Failed to load favorites: $error';
          });
        }
      },
    );
  }

  // Remove the old _loadFavoriteCryptosCount method and replace with:
  Future<void> _updateFavoriteCryptosCount() async {
    try {
      final favoriteIds = await _favoritesService.getFavoriteCryptos();
      if (mounted) {
        setState(() {
          _favoriteCryptosCount = favoriteIds.length;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _favoriteCryptosCount = 0;
        });
      }
    }
  }

  // Update the _onFavoriteCryptosChanged callback:
  void _onFavoriteCryptosChanged() {
    _updateFavoriteCryptosCount();
  }

  Future<void> _loadMySharedPortfolios() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sharedPortfolios')
          .get();

      if (mounted) {
        setState(() {
          _mySharedPortfolios = snapshot.docs.map((doc) => doc.data()).toList();
          _isLoadingSharedPortfolios = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSharedPortfolios = false);
      }
    }
  }

  Future<void> _loadData() async {
    try {} catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
        });
      }
    }
  }

  Future<void> _loadWalletItems() async {
    if (!mounted) return;

    setState(() => _isWalletLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wallets')
          .get();

      List<WalletItem> allItems = [];
      for (var doc in snapshot.docs) {
        final wallet = Wallet.fromJson(doc.data()).copyWith(id: doc.id);
        allItems.addAll(wallet.items);
      }

      setState(() {
        _walletItems = allItems;
      });

      await _calculatePortfolioValues();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred while loading wallet: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isWalletLoading = false);
      }
    }
  }

  Future<void> _calculatePortfolioValues() async {
    double totalValue = 0;
    double totalInvestment = 0;

    try {
      final List<CryptoModel> allCryptos = await _cryptoService.getCryptoData();

      for (var item in _walletItems) {
        final crypto = allCryptos.firstWhere(
          (c) => c.id == item.cryptoId,
          orElse: () => CryptoModel(
            id: item.cryptoId,
            name: item.cryptoName,
            symbol: item.cryptoSymbol,
            image: item.cryptoImage,
            currentPrice: 0,
            priceChangePercentage24h: 0,
            marketCap: 0,
            totalVolume: 0,
            circulatingSupply: 0,
            ath: 0,
            atl: 0,
          ),
        );

        totalValue += item.amount * crypto.currentPrice;
        totalInvestment += item.amount * item.buyPrice;
      }

      double profitLoss = totalValue - totalInvestment;
      double profitLossPercentage =
          totalInvestment > 0 ? (profitLoss / totalInvestment) * 100 : 0;

      if (mounted) {
        setState(() {
          _totalPortfolioValue = totalValue;
          _totalInvestment = totalInvestment;
          _totalProfitLoss = profitLoss;
          _totalProfitLossPercentage = profitLossPercentage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error calculating portfolio: $e';
        });
      }
    }
  }

  String formatPrice(double price) {
    return price
        .toStringAsFixed(5)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  // Build Header Widget (Home screen tarzında)
  Widget _buildHeader(bool isDark) {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _headerAnimation.value)),
          child: Opacity(
            opacity: _headerAnimation.value,
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
                                Icons.person_outline,
                                color: Color(0xFFDFD0B8),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'My Profile',
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
                          'Manage your portfolio & preferences',
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

                  // Action button (Drawer)
                  _buildActionButton(
                    icon: Icons.menu,
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
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

  // Modern Quick Action Card Widget
  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    Color? badgeColor,
    String? badgeText,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDarkMode ? Colors.black : Colors.grey)
                      .withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF222831),
                                fontSize: 16,
                                fontFamily: 'DMSerif',
                              ),
                            ),
                          ),
                          if (badgeText != null && badgeText != "0")
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeColor ?? iconColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                badgeText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey[600],
                          fontSize: 14,
                          fontFamily: 'DMSerif',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.4)
                      : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show Bottom Sheet for content sections
  void _showContentBottomSheet({
    required String title,
    required Widget content,
    required IconData icon,
    required Color iconColor,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          final isDarkMode = theme.brightness == Brightness.dark;

          return Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF222831)
                  : const Color(0xFFDFD0B8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Close button
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.7),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                // Content - direkt section'ı göster
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: content,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) {
      // Bottom sheet kapandığında sayıları güncelle
      _onFavoriteCryptosChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDarkMode ? const Color(0xFF222831) : const Color(0xFFDFD0B8),
      drawer: ProfileDrawer(
        profileImageUrl: _profileImageUrl,
        userName: user?.displayName,
        userEmail: user?.email,
        onProfileTap: () {
          // Profil resmine tıklandığında yapılacak işlem
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _hideAnimation,
              builder: (context, child) {
                return ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: _hideAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, -50 * (1 - _hideAnimation.value)),
                      child: _buildHeader(isDarkMode),
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                child: user == null
                    ? Center(
                        child: Text(
                          'Please log in to view your profile',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isDarkMode
                                ? const Color(0xFFDFD0B8)
                                : const Color(0xFF222831),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          // User Profile Card
                          ProfileHeader(Theme.of(context)),
                          const SizedBox(height: 24),

                          // Portfolio Summary Card
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => WalletsScreen()),
                              );
                            },
                            child: PortfolioSummary(
                              onUpdate: () {
                                _loadWalletItems();
                                if (mounted) {
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Portfolio Distribution Card
                          _buildQuickActionCard(
                            title: "Portfolio Analysis",
                            subtitle: "View your investment distribution",
                            icon: Icons.pie_chart_outline,
                            iconColor: const Color(0xFF4CAF50),
                            onTap: () => _showContentBottomSheet(
                              title: "Portfolio Distribution",
                              icon: Icons.pie_chart_outline,
                              iconColor: const Color(0xFF4CAF50),
                              content: PortfolioDistribution(
                                  walletItems: _walletItems),
                            ),
                          ),

                          // Favorite Cryptos Card
                          _buildQuickActionCard(
                            title: "Favorite Assets",
                            subtitle: "Manage your watchlist",
                            icon: Icons.favorite_outline,
                            iconColor: const Color(0xFFFF6B6B),
                            badgeText: _favoriteCryptosCount > 0
                                ? _favoriteCryptosCount.toString()
                                : null,
                            badgeColor: const Color(0xFFFF6B6B),
                            onTap: () => _showContentBottomSheet(
                              title: "Favorite Cryptocurrencies",
                              icon: Icons.favorite_outline,
                              iconColor: const Color(0xFFFF6B6B),
                              content: const FavoriteCryptosSection(),
                            ),
                          ),

                          // Saved News Card - Badge ile güncellendi
                          _buildQuickActionCard(
                            title: "Saved News",
                            subtitle: "Your bookmarked news",
                            icon: Icons.bookmark_outline,
                            iconColor: const Color(0xFF2196F3),
                            badgeText: _savedNewsCount > 0
                                ? _savedNewsCount.toString()
                                : null,
                            badgeColor: const Color(0xFF2196F3),
                            onTap: () => _showContentBottomSheet(
                              title: "Saved News",
                              icon: Icons.bookmark_outline,
                              iconColor: const Color(0xFF2196F3),
                              content: const SavedNewsSection(),
                            ),
                          ),
                          // Liked Portfolios
                          _buildQuickActionCard(
                            title: "Liked Portfolios",
                            subtitle: "Liked portfolio insights",
                            icon: Icons.library_add_rounded,
                            iconColor: const Color(0xFFFEA405),
                            badgeText: _mySharedPortfolios.isNotEmpty
                                ? _mySharedPortfolios.length.toString()
                                : null,
                            badgeColor: const Color(0xFFFEA405),
                            onTap: () => _showContentBottomSheet(
                              title: "Shared Portfolios",
                              icon: Icons.library_add_outlined,
                              iconColor: const Color(0xFF6420AA),
                              content: const LikedPortfoliosSection(),
                            ),
                          ),
                          // Shared Portfolios Card
                          _buildQuickActionCard(
                            title: "Shared Portfolios",
                            subtitle: "Community portfolio insights",
                            icon: Icons.share_outlined,
                            iconColor: const Color(0xFF9C27B0),
                            badgeText: _mySharedPortfolios.isNotEmpty
                                ? _mySharedPortfolios.length.toString()
                                : null,
                            badgeColor: const Color(0xFF9C27B0),
                            onTap: () => _showContentBottomSheet(
                              title: "Shared Portfolios",
                              icon: Icons.share_outlined,
                              iconColor: const Color(0xFF9C27B0),
                              content: const SharedPortfoliosSection(),
                            ),
                          ),

                          const SizedBox(height: 10),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
