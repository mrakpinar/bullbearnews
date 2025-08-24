import 'package:bullbearnews/models/wallet_model.dart';
import 'package:bullbearnews/screens/profile/wallet/wallet_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class SavedPortfoliosSection extends StatefulWidget {
  const SavedPortfoliosSection({super.key});

  @override
  State<SavedPortfoliosSection> createState() => _SavedPortfoliosSectionState();
}

class _SavedPortfoliosSectionState extends State<SavedPortfoliosSection>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _likedPortfolios = [];
  bool _isLoading = true;
  String _errorMessage = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadLikedPortfolios();
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

  Future<void> _loadLikedPortfolios() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
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

      // Get liked portfolio IDs
      final likedSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('likedPortfolios')
          .get();

      List<Map<String, dynamic>> portfolios = [];

      for (var likedDoc in likedSnapshot.docs) {
        final walletId = likedDoc.id;
        final ownerId = likedDoc.data()['ownerId'] as String;
        final likedAt = likedDoc.data()['likedAt'] as Timestamp?;

        try {
          // Get owner info
          final ownerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(ownerId)
              .get();

          if (!ownerDoc.exists) continue;

          // Get wallet info
          final walletDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(ownerId)
              .collection('wallets')
              .doc(walletId)
              .get();

          if (!walletDoc.exists) continue;

          // Get shared portfolio info for likes count
          final sharedPortfolioDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(ownerId)
              .collection('sharedPortfolios')
              .doc(walletId)
              .get();

          final wallet =
              Wallet.fromJson(walletDoc.data()!).copyWith(id: walletDoc.id);
          final ownerData = ownerDoc.data()!;
          final likes = sharedPortfolioDoc.exists
              ? (sharedPortfolioDoc.data()!['likes'] as List? ?? []).length
              : 0;

          portfolios.add({
            'wallet': wallet,
            'ownerId': ownerId,
            'ownerName':
                ownerData['nickname'] ?? ownerData['email'] ?? 'Unknown',
            'ownerProfileImage': ownerData['profileImageUrl'],
            'likedAt': likedAt,
            'likesCount': likes,
          });
        } catch (e) {
          print('Error loading portfolio $walletId: $e');
          continue;
        }
      }

      // Sort by liked date (newest first)
      portfolios.sort((a, b) {
        final aDate = a['likedAt'] as Timestamp?;
        final bDate = b['likedAt'] as Timestamp?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      if (mounted) {
        setState(() {
          _likedPortfolios = portfolios;
          _isLoading = false;
          _errorMessage = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading liked portfolios: $e';
        });
      }
    }
  }

  Future<void> _showRemoveLikedDialog(
      Map<String, dynamic> portfolioData) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final wallet = portfolioData['wallet'] as Wallet;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF393E46) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bookmark_border,
                  color: Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Remove from Saved',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF222831),
                    fontFamily: 'DMSerif',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF222831).withOpacity(0.5)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.withOpacity(0.1),
                              Colors.blue.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.wallet_outlined,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wallet.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              'by ${portfolioData['ownerName']}',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to remove this portfolio from your saved items? You can always save it again later.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : const Color(0xFF393E46),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.grey[800] : Colors.grey[200],
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        const SizedBox(width: 8),
                        const Text('Cancel'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _removeLikedPortfolio(portfolioData);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_remove_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text('Remove'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeLikedPortfolio(Map<String, dynamic> portfolioData) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final wallet = portfolioData['wallet'] as Wallet;
      final ownerId = portfolioData['ownerId'] as String;

      // Remove from current user's liked portfolios
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('likedPortfolios')
          .doc(wallet.id)
          .delete();

      // Remove like from the original shared portfolio
      await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .collection('sharedPortfolios')
          .doc(wallet.id)
          .update({
        'likes': FieldValue.arrayRemove([currentUserId])
      });

      // Refresh the list
      await _loadLikedPortfolios();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Portfolio removed from saved items',
                  style: TextStyle(fontFamily: 'DMSerif'),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
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
                    'Error removing portfolio: $e',
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
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
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
          title: 'Saved Portfolios',
          isDark: isDark,
          child: _buildContent(isDark),
        ),
      ),
    );
  }

  Widget _buildModernSection({
    required String title,
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
                  Colors.orange.withOpacity(0.1),
                  Colors.deepOrange.withOpacity(0.1),
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
                          '${_likedPortfolios.length} saved portfolios',
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
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: Colors.orange,
                        size: isSmallScreen ? 18 : 20,
                      ),
                      onPressed: _loadLikedPortfolios,
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

    if (_likedPortfolios.isEmpty) {
      return _buildEmptyStateCard(isDark);
    }

    return Center(
      child: Column(
        children: _likedPortfolios
            .map((portfolioData) =>
                _buildSavedPortfolioItem(portfolioData, isDark))
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
              color: Colors.orange,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading saved portfolios...',
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
            onPressed: _loadLikedPortfolios,
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
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                color: Colors.orange,
                size: isSmallScreen ? 36 : 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Saved Portfolios',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.lightText : AppColors.darkText,
                fontFamily: 'DMSerif',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore other users\' portfolios and save\nthe ones you find interesting',
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

  Widget _buildSavedPortfolioItem(
      Map<String, dynamic> portfolioData, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final wallet = portfolioData['wallet'] as Wallet;

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
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, animation, secondaryAnimation) =>
                    WalletDetailScreen(
                  wallet: wallet,
                  onUpdate: () {},
                  isSharedView: true,
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      )),
                      child: child,
                    ),
                  );
                },
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
                        Colors.orange.withOpacity(0.2),
                        Colors.deepOrange.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.wallet_outlined,
                    color: Colors.orange.shade600,
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
                          color:
                              isDark ? AppColors.lightText : AppColors.darkText,
                          fontFamily: 'DMSerif',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade300,
                            ),
                            child: ClipOval(
                              child:
                                  portfolioData['ownerProfileImage'] != null &&
                                          portfolioData['ownerProfileImage']
                                              .toString()
                                              .isNotEmpty
                                      ? Image.network(
                                          portfolioData['ownerProfileImage'],
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              size: 12,
                                              color: Colors.grey[600],
                                            );
                                          },
                                        )
                                      : Icon(
                                          Icons.person,
                                          size: 12,
                                          color: Colors.grey[600],
                                        ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'by ${portfolioData['ownerName']} • ${_formatDate(portfolioData['likedAt'])}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Portfolio Stats
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  isDark ? Colors.grey[700] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${wallet.items.length} assets',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                                fontSize: isSmallScreen ? 10 : 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.favorite_outlined,
                                size: isSmallScreen ? 12 : 14,
                                color: Colors.red.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${portfolioData['likesCount']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 11 : 12,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Remove Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.bookmark_rounded,
                      color: Colors.orange.shade600,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    onPressed: () => _showRemoveLikedDialog(portfolioData),
                    tooltip: 'Remove from saved',
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
  }
}
