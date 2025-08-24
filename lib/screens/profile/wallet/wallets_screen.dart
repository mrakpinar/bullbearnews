import 'package:bullbearnews/models/wallet_model.dart';
import 'package:bullbearnews/screens/profile/wallet/wallet_detail_screen.dart';
import 'package:bullbearnews/services/crypto_service.dart';
import 'package:bullbearnews/services/notification_service.dart';
import 'package:bullbearnews/constants/colors.dart';
import 'package:bullbearnews/widgets/wallet/wallet_card_widget.dart';
import 'package:bullbearnews/widgets/wallet/wallet_empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_wallet_screen.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CryptoService _cryptoService = CryptoService();
  final NotificationService _notificationService = NotificationService();

  List<Wallet> _wallets = [];
  Set<String> _sharedWalletIds = {};
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadWallets();
    _loadSharedWallets();
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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wallets')
          .get();

      if (mounted) {
        setState(() {
          _wallets = snapshot.docs
              .map((doc) => Wallet.fromJson(doc.data()).copyWith(id: doc.id))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error loading wallets: $e'),
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

  Future<void> _loadSharedWallets() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sharedPortfolios')
          .get();

      if (mounted) {
        setState(() {
          _sharedWalletIds = snapshot.docs.map((doc) => doc.id).toSet();
        });
      }
    } catch (e) {
      print('Error loading shared wallets: $e');
    }
  }

  Future<void> _deleteWallet(String walletId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Wallet'ı sil
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wallets')
          .doc(walletId)
          .delete();

      // Eğer paylaşılmışsa paylaşım kaydını da sil
      if (_sharedWalletIds.contains(walletId)) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('sharedPortfolios')
            .doc(walletId)
            .delete();
      }

      if (mounted) {
        setState(() {
          _wallets.removeWhere((wallet) => wallet.id == walletId);
          _sharedWalletIds.remove(walletId);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error deleting wallet: $e'),
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

  Future<void> _shareWallet(Wallet wallet) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Önce onay dialogu göster
      final shouldShare = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkCard
              : AppColors.lightCard,
          title: Text(
            'Share Portfolio',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.lightText
                  : AppColors.darkText,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'DMSerif',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Do you want to share "${wallet.name}" publicly?',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.lightText.withOpacity(0.8)
                      : AppColors.darkText.withOpacity(0.8),
                  fontFamily: 'DMSerif',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your followers will be notified about this portfolio.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                          fontFamily: 'DMSerif',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context, false),
                  icon: Icon(Icons.cancel, color: Colors.grey.shade600),
                  label: Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontFamily: 'DMSerif',
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.green.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.share, color: Colors.white),
                    label: const Text(
                      'Share',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'DMSerif',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      if (shouldShare != true) return;

      // Paylaşım bilgisini Firestore'a kaydet
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sharedPortfolios')
          .doc(wallet.id)
          .set({
        'walletId': wallet.id,
        'sharedAt': FieldValue.serverTimestamp(),
        'isPublic': true,
        'viewCount': 0,
        'likes': [],
      });

      // Takipçilere bildirim gönder
      await _notificationService.sendSharePortfolioNotification(
          wallet.name, wallet.id);

      // Paylaşılan wallet'ları yeniden yükle
      await _loadSharedWallets();

      // Başarı mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Portfolio shared successfully! Your followers have been notified.',
                    style: TextStyle(
                      fontFamily: 'DMSerif',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error sharing portfolio: $e',
                    style: TextStyle(
                      fontFamily: 'DMSerif',
                      fontWeight: FontWeight.w500,
                    ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'My Wallets',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.lightText : AppColors.darkText,
            fontFamily: 'DMSerif',
          ),
        ),
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: isDark ? AppColors.lightText : AppColors.darkText,
            ),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddWalletScreen()),
                  );
                  _loadWallets();
                  _loadSharedWallets();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        color: AppColors.whiteText,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add',
                        style: TextStyle(
                          color: AppColors.whiteText,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'DMSerif',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadWallets();
            await _loadSharedWallets();
          },
          color: AppColors.secondary,
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: AppColors.secondary,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading your wallets...',
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
                )
              : _wallets.isEmpty
                  ? WalletEmptyStateWidget(
                      isDark: isDark,
                      loadSharedWallets: _loadSharedWallets,
                      loadWallets: _loadWallets,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _wallets.length,
                      itemBuilder: (context, index) {
                        final wallet = _wallets[index];
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          curve: Curves.easeOutBack,
                          child: GestureDetector(
                            onLongPress: () => _showDeleteDialog(wallet),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WalletDetailScreen(
                                    wallet: wallet,
                                    onUpdate: () {
                                      _loadWallets();
                                      _loadSharedWallets();
                                    },
                                  ),
                                ),
                              );
                            },
                            child: WalletCardWidget(
                              wallet: wallet,
                              isShared: _sharedWalletIds.contains(wallet.id),
                              isDark: isDark,
                              onSharePressed: () => _shareWallet(wallet),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WalletDetailScreen(
                                      wallet: wallet,
                                      onUpdate: () {
                                        _loadWallets();
                                        _loadSharedWallets();
                                      },
                                    ),
                                  ),
                                );
                              },
                              cryptoService: _cryptoService,
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(Wallet wallet) async {
    final isShared = _sharedWalletIds.contains(wallet.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        title: Text(
          'Delete Wallet',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red.shade600,
            fontFamily: 'DMSerif',
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${wallet.name}"?',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.lightText : AppColors.darkText,
                fontFamily: 'DMSerif',
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: Colors.red.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. All wallet data will be permanently deleted.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade600,
                        fontFamily: 'DMSerif',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isShared) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.public_off_rounded,
                      color: Colors.orange.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This portfolio is shared publicly. Deleting it will also remove it from public view.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade600,
                          fontFamily: 'DMSerif',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context, false),
                icon: Icon(Icons.cancel_rounded, color: Colors.grey.shade600),
                label: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontFamily: 'DMSerif',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                  label: const Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'DMSerif',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteWallet(wallet.id);
    }
  }
}
