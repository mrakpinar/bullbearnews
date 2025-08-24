import 'package:bullbearnews/models/wallet_model.dart';
import 'package:bullbearnews/screens/profile/wallet/edit_asset_screen.dart';
import 'package:bullbearnews/services/crypto_service.dart';
import 'package:bullbearnews/models/crypto_model.dart';
import 'package:bullbearnews/widgets/wallet_detail/portfolio_summary_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_to_wallet_screen.dart';

class WalletDetailScreen extends StatefulWidget {
  final Wallet wallet;
  final bool isSharedView;
  final String? ownerId; // Portfolio sahibinin ID'si (shared view için)
  final Function() onUpdate;

  const WalletDetailScreen({
    super.key,
    required this.wallet,
    required this.onUpdate,
    this.isSharedView = false,
    this.ownerId,
  });

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  late Wallet _wallet;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CryptoService _cryptoService = CryptoService();

  final TextEditingController _nameController = TextEditingController();
  bool _isEditingName = false;

  Map<String, dynamic>? _ownerInfo;
  List<CryptoModel> _cryptoData = [];
  bool _isLoadingCrypto = true;

  @override
  void initState() {
    super.initState();
    _wallet = widget.wallet;
    _nameController.text = _wallet.name;

    _loadCryptoData();

    if (widget.isSharedView && widget.ownerId != null) {
      _loadOwnerInfo();
      _incrementViewCount();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateWalletName() async {
    if (_nameController.text.trim().isEmpty) return;
    if (_nameController.text.trim() == _wallet.name) {
      setState(() => _isEditingName = false);
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wallets')
          .doc(_wallet.id)
          .update({
        'name': _nameController.text.trim(),
      });

      if (mounted) {
        setState(() {
          _wallet = _wallet.copyWith(name: _nameController.text.trim());
          _isEditingName = false;
        });
        widget.onUpdate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wallet name updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating wallet name: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCryptoData() async {
    try {
      final cryptos = await _cryptoService.getCryptoData();
      if (mounted) {
        setState(() {
          _cryptoData = cryptos;
          _isLoadingCrypto = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCrypto = false);
      }
    }
  }

  Future<void> _loadOwnerInfo() async {
    if (widget.ownerId == null) return;

    try {
      final ownerDoc =
          await _firestore.collection('users').doc(widget.ownerId!).get();

      if (ownerDoc.exists && mounted) {
        setState(() {
          _ownerInfo = ownerDoc.data();
        });
      }
    } catch (e) {
      print('Error loading owner info: $e');
    }
  }

  Future<void> _incrementViewCount() async {
    if (widget.ownerId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(widget.ownerId!)
          .collection('sharedPortfolios')
          .doc(_wallet.id)
          .update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  // Asset silme confirmation dialogu
  Future<bool?> _confirmDeleteAsset(WalletItem item) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[850] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Delete Asset',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                    fontFamily: 'DMSerif',
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    ClipOval(
                      child: item.cryptoImage.isEmpty
                          ? Container(
                              width: 32,
                              height: 32,
                              color: Colors.grey[300],
                              child:
                                  const Icon(Icons.currency_bitcoin, size: 16),
                            )
                          : Image.network(
                              item.cryptoImage,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 32,
                                  height: 32,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.error, size: 16),
                                );
                              },
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.cryptoName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                              fontFamily: 'DMSerif',
                            ),
                          ),
                          Text(
                            '${_formatAmount(item.amount)} ${item.cryptoSymbol.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontFamily: 'DMSerif',
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
                'Are you sure you want to delete this asset from your portfolio?',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontFamily: 'DMSerif',
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
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
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(context).pop(false),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              fontFamily: 'DMSerif',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(context).pop(true),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_forever,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  fontFamily: 'DMSerif',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

// Asset silme fonksiyonu
  Future<void> _deleteAsset(WalletItem item) async {
    try {
      // Optimistic update - UI'yi hemen güncelle
      final updatedItems = _wallet.items.where((i) => i.id != item.id).toList();

      if (mounted) {
        setState(() {
          _wallet = _wallet.copyWith(items: updatedItems);
        });
      }

      // Firestore'u güncelle
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('wallets')
          .doc(_wallet.id)
          .update({
        'items': updatedItems.map((e) => e.toJson()).toList(),
      });

      widget.onUpdate();

      // Başarı mesajı
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${item.cryptoName} removed from portfolio',
                    style: TextStyle(
                      fontFamily: 'DMSerif',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () => _undoDeleteAsset(item),
            ),
          ),
        );
      }
    } catch (e) {
      // Hata durumunda geri al
      await _loadWallet();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error deleting asset: $e',
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

// Undo delete fonksiyonu
  Future<void> _undoDeleteAsset(WalletItem item) async {
    try {
      final updatedItems = [..._wallet.items, item];

      if (mounted) {
        setState(() {
          _wallet = _wallet.copyWith(items: updatedItems);
        });
      }

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('wallets')
          .doc(_wallet.id)
          .update({
        'items': updatedItems.map((e) => e.toJson()).toList(),
      });

      widget.onUpdate();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.restore,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '${item.cryptoName} restored to portfolio',
                  style: TextStyle(
                    fontFamily: 'DMSerif',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error restoring asset: $e');
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
          title: const Text(
            'Share Portfolio',
            style: TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'DMSerif',
            ),
          ),
          content: Text(
            'Do you want to share this portfolio publicly?',
            style: TextStyle(
                fontSize: 16, color: Theme.of(context).colorScheme.secondary),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Share',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
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

      // Başarı mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Portfolio shared successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing portfolio: $e')),
        );
      }
    }
  }

  Future<void> _addToWallet() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddToWalletScreen(),
        settings: RouteSettings(arguments: _wallet.id),
      ),
    );

    if (result == true) {
      await _loadWallet();
      widget.onUpdate();
    }
  }

  Future<void> _loadWallet() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wallets')
          .doc(_wallet.id)
          .get();

      if (mounted) {
        setState(() {
          _wallet = Wallet.fromJson(doc.data()!).copyWith(id: doc.id);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading wallet: $e')),
        );
      }
    }
  }

  Future<void> _editAsset(WalletItem item) async {
    final updatedItem = await Navigator.push<WalletItem>(
      context,
      MaterialPageRoute(
        builder: (context) => EditAssetScreen(
          item: item,
          onSave: (updatedItem) async {
            try {
              final updatedItems = _wallet.items
                  .map((i) => i.id == updatedItem.id ? updatedItem : i)
                  .toList();

              if (mounted) {
                setState(() {
                  _wallet = _wallet.copyWith(items: updatedItems);
                });
              }

              await _firestore
                  .collection('users')
                  .doc(_auth.currentUser!.uid)
                  .collection('wallets')
                  .doc(_wallet.id)
                  .update({
                'items': updatedItems.map((e) => e.toJson()).toList(),
              });

              widget.onUpdate();
              return updatedItem;
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating asset: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              rethrow;
            }
          },
        ),
      ),
    );

    if (updatedItem != null && mounted) {
      await _loadWallet();
    }
  }

  double _calculateCurrentValue() {
    if (_isLoadingCrypto || _cryptoData.isEmpty) return 0;
    return _wallet.calculateCurrentValue(_cryptoData);
  }

  double _calculateProfitLoss() {
    final currentValue = _calculateCurrentValue();
    final investmentValue = _wallet.totalInvestmentValue;
    return currentValue - investmentValue;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: _isEditingName
            ? TextField(
                controller: _nameController,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                  fontFamily: 'DMSerif',
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Wallet name',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: _updateWalletName,
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _isEditingName = false;
                            _nameController.text = _wallet.name;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                onSubmitted: (_) => _updateWalletName(),
              )
            : Column(
                children: [
                  GestureDetector(
                    onTap: widget.isSharedView
                        ? null
                        : () => setState(() => _isEditingName = true),
                    child: Text(
                      _wallet.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                        fontFamily: 'DMSerif',
                      ),
                    ),
                  ),
                  if (widget.isSharedView && _ownerInfo != null)
                    Text(
                      'by ${_ownerInfo!['nickname'] ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontFamily: 'DMSerif',
                      ),
                    ),
                ],
              ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white,
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
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          if (!widget.isSharedView) ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                tooltip: 'Add Asset',
                onPressed: _addToWallet,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                tooltip: 'Share Portfolio',
                onPressed: () => _shareWallet(_wallet),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                tooltip: 'Delete Wallet',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text(
                        'Delete Wallet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontFamily: 'DMSerif',
                        ),
                      ),
                      content: const Text(
                        'Are you sure you want to delete this wallet? This action cannot be undone.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      actions: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).cardTheme.color,
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.tertiary),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).cardTheme.color,
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      final user = _auth.currentUser;
                      if (user == null) throw Exception('User not logged in');
                      await _firestore
                          .collection('users')
                          .doc(user.uid)
                          .collection('wallets')
                          .doc(_wallet.id)
                          .delete();
                      widget.onUpdate();
                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting wallet: $e')),
                      );
                    }
                  }
                },
              ),
            ),
          ] else ...[
            // Shared view actions
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.visibility, color: Colors.white),
                tooltip: 'View Only',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This is a shared portfolio. You can only view it.',
                              style: TextStyle(fontFamily: 'DMSerif'),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.orange.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Portfolio Summary Card
          PortfolioSummaryWidget(
            isDark: isDark,
            isLoadingCrypto: _isLoadingCrypto,
            currentValue: _calculateCurrentValue(),
            profitLoss: _calculateProfitLoss(),
            totalInvestmentValue: _wallet.totalInvestmentValue,
            assetCount: _wallet.items.length,
          ),

          // Assets List
          Expanded(
            child: _wallet.items.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _wallet.items.length,
                    itemBuilder: (context, index) {
                      final item = _wallet.items[index];
                      return _buildAssetCard(item, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wallet,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.isSharedView
                ? 'No assets in this portfolio'
                : 'This wallet is empty',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isSharedView
                ? 'This portfolio doesn\'t contain any assets yet'
                : 'Add some assets to start tracking your investments',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'DMSerif',
            ),
          ),
          if (!widget.isSharedView) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addToWallet,
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Assets',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'DMSerif',
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Akıllı amount formatlama fonksiyonu
  String _formatAmount(double amount) {
    if (amount == 0) return '0';

    // Eğer amount 1'den büyükse, gereksiz sıfırları kaldır
    if (amount >= 1) {
      // Tam sayı ise sıfır gösterme
      if (amount == amount.truncate()) {
        return amount.truncate().toString();
      }
      // 1'den büyük ama ondalıklı ise max 4 basamak
      return amount
          .toStringAsFixed(4)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }

    // 1'den küçük değerler için
    if (amount >= 0.1) {
      return amount
          .toStringAsFixed(4)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    } else if (amount >= 0.01) {
      return amount
          .toStringAsFixed(6)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    } else {
      return amount
          .toStringAsFixed(8)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
  }

  Widget _buildAssetCard(WalletItem item, bool isDark) {
    final currentPrice = _cryptoData
        .firstWhere(
          (crypto) => crypto.id == item.cryptoId,
          orElse: () => CryptoModel(
            id: item.cryptoId,
            name: item.cryptoName,
            symbol: item.cryptoSymbol,
            image: item.cryptoImage,
            currentPrice: item.buyPrice,
            marketCap: 0.0,
            totalVolume: 0.0,
            circulatingSupply: 0.0,
            priceChangePercentage24h: 0.0,
            ath: 0.0,
            atl: 0.0,
          ),
        )
        .currentPrice;

    final currentValue = item.amount * currentPrice;
    final investedValue = item.amount * item.buyPrice;
    final profitLoss = currentValue - investedValue;
    final isProfit = profitLoss >= 0;

    // Shared view için sadece görüntüleme
    if (widget.isSharedView) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildAssetCardContent(
                item, currentValue, profitLoss, isProfit, isDark, false),
          ),
        ),
      );
    }

    // Normal view için swipe-to-delete
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(item.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade400, Colors.red.shade600],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_forever,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'DMSerif',
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) => _confirmDeleteAsset(item),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _editAsset(item),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildAssetCardContent(
                  item, currentValue, profitLoss, isProfit, isDark, true),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssetCardContent(WalletItem item, double currentValue,
      double profitLoss, bool isProfit, bool isDark, bool showEditIcon) {
    return Row(
      children: [
        // Crypto Image
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: item.cryptoImage.isEmpty
                ? Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.currency_bitcoin, size: 24),
                  )
                : Image.network(
                    item.cryptoImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error, size: 24),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(width: 16),

        // Crypto Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.cryptoName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                  fontFamily: 'DMSerif',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatAmount(item.amount)} ${item.cryptoSymbol.toUpperCase()}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontFamily: 'DMSerif',
                ),
              ),
            ],
          ),
        ),

        // Value Info
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${_formatCurrency(currentValue)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
                fontFamily: 'DMSerif',
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (isProfit ? Colors.green : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isProfit ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isProfit ? Colors.green : Colors.red,
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '\$${_formatCurrency(profitLoss.abs())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isProfit ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'DMSerif',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Action buttons
        if (showEditIcon) ...[
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? Colors.white54 : Colors.black54,
              size: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: isDark ? Colors.grey[800] : Colors.white,
            onSelected: (value) {
              if (value == 'edit') {
                _editAsset(item);
              } else if (value == 'delete') {
                _confirmDeleteAsset(item).then((confirmed) {
                  if (confirmed == true) {
                    _deleteAsset(item);
                  }
                });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: Colors.blueGrey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Edit Asset',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontFamily: 'DMSerif',
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Delete Asset',
                      style: TextStyle(
                        color: Colors.red,
                        fontFamily: 'DMSerif',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Para birimi formatlama fonksiyonu
  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    } else if (value >= 1) {
      return value.toStringAsFixed(2);
    } else if (value >= 0.01) {
      return value
          .toStringAsFixed(4)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    } else {
      return value
          .toStringAsFixed(6)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
  }
}
