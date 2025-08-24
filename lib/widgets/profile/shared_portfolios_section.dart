import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/wallet_model.dart';
import '../../screens/profile/wallet/wallet_detail_screen.dart';
import '../../constants/colors.dart';

class SharedPortfoliosSection extends StatefulWidget {
  const SharedPortfoliosSection({super.key});

  @override
  State<SharedPortfoliosSection> createState() =>
      _SharedPortfoliosSectionState();
}

class _SharedPortfoliosSectionState extends State<SharedPortfoliosSection>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _mySharedPortfolios = [];
  bool _isLoading = true;
  String _errorMessage = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadMySharedPortfolios();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMySharedPortfolios() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in';
        });
      }
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sharedPortfolios')
          .get();

      if (mounted) {
        setState(() {
          _mySharedPortfolios = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              ...data,
              'id': doc.id,
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load shared portfolios: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _buildModernSection(
          title: 'Shared Portfolios',
          // icon: Icons.share_rounded,
          isDark: isDark,
          child: _buildContent(isDark),
        ),
      ),
    );
  }

  Widget _buildModernSection({
    required String title,
    // required IconData icon,
    required bool isDark,
    required Widget child,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF9C27B0).withOpacity(0.1),
                  Color.fromARGB(255, 216, 113, 235).withOpacity(0.1),
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
                // Container(
                //   padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                //   decoration: BoxDecoration(
                //     gradient: const LinearGradient(
                //       colors: [
                //         Color(0xFF9C27B0),
                //         Color.fromARGB(255, 201, 68, 224)
                //       ],
                //     ),
                //     borderRadius: BorderRadius.circular(16),
                //     boxShadow: [
                //       BoxShadow(
                //         color: Color(0xFF9C27B0).withOpacity(0.3),
                //         blurRadius: 8,
                //         offset: const Offset(0, 4),
                //       ),
                //     ],
                //   ),
                // child: Icon(
                //   icon,
                //   color: AppColors.whiteText,
                //   size: isSmallScreen ? 20 : 24,
                // ),
                // ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 24,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? AppColors.lightText : AppColors.darkText,
                          fontFamily: 'DMSerif',
                        ),
                      ),
                      if (!_isLoading && _errorMessage.isEmpty)
                        Text(
                          '${_mySharedPortfolios.length} shared portfolios',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: isDark
                                ? AppColors.lightText.withOpacity(0.7)
                                : AppColors.darkText.withOpacity(0.7),
                            fontFamily: 'DMSerif',
                          ),
                        ),
                    ],
                  ),
                ),
                if (!_isLoading && _errorMessage.isEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF9C27B0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFF9C27B0),
                        size: isSmallScreen ? 18 : 20,
                      ),
                      onPressed: _loadMySharedPortfolios,
                      tooltip: 'Refresh',
                      constraints: BoxConstraints(
                        minWidth: isSmallScreen ? 32 : 40,
                        minHeight: isSmallScreen ? 32 : 40,
                      ),
                      padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return _buildLoadingCard(isDark);
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorCard(isDark);
    }

    if (_mySharedPortfolios.isEmpty) {
      return _buildEmptyStateCard(isDark);
    }

    return Center(
      child: Column(
        children: _mySharedPortfolios
            .map((portfolio) => _buildSharedPortfolioItem(portfolio, isDark))
            .toList(),
      ),
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const CircularProgressIndicator(
              color: Colors.green,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading shared portfolios...',
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppColors.lightText.withOpacity(0.7)
                    : AppColors.darkText.withOpacity(0.7),
                fontFamily: 'DMSerif',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
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
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade600,
              size: isSmallScreen ? 36 : 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to Load Portfolios',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.red.shade500,
              fontFamily: 'DMSerif',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadMySharedPortfolios,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 24,
                vertical: isSmallScreen ? 8 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Center(
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
        decoration: BoxDecoration(
          color: Color(0xFF9C27B0).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(0xFF9C27B0).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: Color(0xFF9C27B0).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.share_outlined,
                color: Color(0xFF9C27B0),
                size: isSmallScreen ? 36 : 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Shared Portfolios',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.lightText : AppColors.darkText,
                fontFamily: 'DMSerif',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your portfolios with others to\nsee them appear here',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: isDark
                    ? AppColors.lightText.withOpacity(0.7)
                    : AppColors.darkText.withOpacity(0.7),
                fontFamily: 'DMSerif',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedPortfolioItem(
      Map<String, dynamic> portfolio, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('wallets')
          .doc(portfolio['walletId'])
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark
                        ? AppColors.lightText.withOpacity(0.1)
                        : AppColors.darkText.withOpacity(0.1),
                  ),
                ),
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 16),
                      Expanded(child: Text('Loading portfolio...')),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.red.withOpacity(0.3)),
              ),
              color: Colors.red.withOpacity(0.1),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontFamily: 'DMSerif',
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.orange.withOpacity(0.3)),
              ),
              color: Colors.orange.withOpacity(0.1),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade600),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Portfolio not found',
                        style: TextStyle(fontFamily: 'DMSerif'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red.shade600),
                      onPressed: () => _unsharePortfolio(portfolio['walletId']),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final wallet =
            Wallet.fromJson(snapshot.data!.data() as Map<String, dynamic>);
        final likesCount = portfolio['likes']?.length ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark
                    ? AppColors.lightText.withOpacity(0.2)
                    : AppColors.darkText.withOpacity(0.1),
              ),
            ),
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WalletDetailScreen(
                      wallet: wallet,
                      onUpdate: _loadMySharedPortfolios,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: Row(
                  children: [
                    // Portfolio Icon
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withOpacity(0.2),
                            Colors.teal.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.wallet_outlined,
                        color: Colors.green.shade600,
                        size: isSmallScreen ? 24 : 28,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),

                    // Portfolio Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wallet.name,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.lightText
                                  : AppColors.darkText,
                              fontFamily: 'DMSerif',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Responsive badge layout
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.bookmark_outline_sharp,
                                      size: isSmallScreen ? 12 : 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        "Total saves: $likesCount",
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 10 : 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'DMSerif',
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Delete Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red.shade600,
                          size: isSmallScreen ? 20 : 24,
                        ),
                        onPressed: () =>
                            _unsharePortfolio(portfolio['walletId']),
                        tooltip: 'Unshare portfolio',
                        constraints: BoxConstraints(
                          minWidth: isSmallScreen ? 32 : 40,
                          minHeight: isSmallScreen ? 32 : 40,
                        ),
                        padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _unsharePortfolio(String walletId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Unshare Portfolio',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'DMSerif',
            fontSize: 20,
          ),
        ),
        content: Text(
          'Do you want to stop sharing this portfolio? It will no longer be visible to other users.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontFamily: 'DMSerif',
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.cancel, color: Colors.grey),
                label: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'DMSerif',
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: Icon(Icons.delete_forever, color: Colors.red.shade600),
                label: Text(
                  'Unshare',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontFamily: 'DMSerif',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('sharedPortfolios')
              .doc(walletId)
              .delete();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Portfolio unshared successfully',
                      style: TextStyle(fontFamily: 'DMSerif'),
                    ),
                  ],
                ),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }

          _loadMySharedPortfolios();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Failed to unshare: $e',
                      style: const TextStyle(fontFamily: 'DMSerif'),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }
}
