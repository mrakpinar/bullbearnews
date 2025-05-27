import 'package:bullbearnews/models/crypto_model.dart';
import 'package:bullbearnews/models/wallet_model.dart';
import 'package:bullbearnews/screens/profile/wallet_detail_screen.dart';
import 'package:bullbearnews/services/crypto_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'add_wallet_screen.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CryptoService _cryptoService = CryptoService();

  List<Wallet> _wallets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wallets')
          .get();

      setState(() {
        _wallets = snapshot.docs
            .map((doc) => Wallet.fromJson(doc.data()).copyWith(id: doc.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading wallets: $e')),
      );
    }
  }

  Future<void> _deleteWallet(String walletId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wallets')
          .doc(walletId)
          .delete();

      setState(() {
        _wallets.removeWhere((wallet) => wallet.id == walletId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting wallet: $e')),
      );
    }
  }

  Future<void> _shareWallet(Wallet wallet) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

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

      // Paylaşılabilir link oluştur
      final shareLink =
          'https://yourapp.com/portfolio/${user.uid}/${wallet.id}';
      final shareText = 'Check out my crypto portfolio: $shareLink';

      // Paylaşım dialogu göster
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Portfolio Shared'),
          content: Text('Your portfolio has been shared successfully!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Share.share(shareText); // share_plus paketi gereklidir
              },
              child: Text('Share Link'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing portfolio: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallets',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            )),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 30),
          tooltip: 'Back',
          // Back button
          // This will navigate back to the previous screen
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_sharp, size: 30),
            tooltip: 'Add Wallet',
            // Add Wallet button
            // This will navigate to the AddWalletScreen
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddWalletScreen()),
              );
              _loadWallets();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWallets,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: Colors.blue, strokeWidth: 2.0),
              )
            : _wallets.isEmpty
                ? _buildEmptyState()
                : _wallets.length == 1 && _wallets.first.items.isEmpty
                    ? _buildEmptyState()
                    : _wallets.length == 1 &&
                            _wallets.first.items.isNotEmpty &&
                            _wallets.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _wallets.length,
                            itemBuilder: (context, index) {
                              final wallet = _wallets[index];
                              return _buildWalletCard(wallet);
                            },
                          ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wallet, size: 64),
          const SizedBox(height: 16),
          const Text(
            'No wallets yet',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddWalletScreen()),
              );
              _loadWallets();
            },
            child: Text(
              'Create Your First Wallet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(Wallet wallet) {
    return FutureBuilder<List<CryptoModel>>(
      future: _cryptoService.getCryptoData(),
      builder: (context, snapshot) {
        final isLoading = !snapshot.hasData;
        final currentValue =
            isLoading ? 0 : wallet.calculateCurrentValue(snapshot.data!);
        final investmentValue = wallet.totalInvestmentValue;
        final profitLoss = currentValue - investmentValue;
        final isProfit = profitLoss >= 0;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.wallet,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          wallet.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.share,
                        size: 24,
                        color: Colors.blue,
                      ),
                      tooltip: 'Share Wallet',
                      onPressed: () {
                        _shareWallet(wallet);
                        final shareText =
                            'Wallet: ${wallet.name}\nAssets: ${wallet.items.length}\nCurrent Value: \$${currentValue.toStringAsFixed(2)}\nProfit/Loss: \$${profitLoss.abs().toStringAsFixed(2)} ${isProfit ? "(Profit)" : "(Loss)"}';
                        // You can use Share.share from the 'share_plus' package here
                        // For now, just show a snackbar as a placeholder
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Share: $shareText')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${wallet.items.length} assets',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                    isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${currentValue.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.amber
                                      : Colors.blue,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    isProfit
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    size: 14,
                                    color: isProfit ? Colors.green : Colors.red,
                                  ),
                                  Text(
                                    '\$${profitLoss.abs().toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          isProfit ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onLongPress: () {
                    // Show delete dialog
                    _showDeleteDialog(wallet);
                  },
                  onPressed: () {
                    // Navigate to WalletDetailScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WalletDetailScreen(
                          wallet: wallet,
                          onUpdate: () {
                            // Reload wallets when returning from WalletDetailScreen
                            _loadWallets();
                          },
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                    foregroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDeleteDialog(Wallet wallet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wallet', style: TextStyle(color: Colors.red)),
        content: Text(
          'Are you sure you want to delete ${wallet.name}?',
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.blue,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteWallet(wallet.id);
    }
  }
}
