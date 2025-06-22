import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/wallet_model.dart';
import '../../screens/profile/wallet_detail_screen.dart';

class SharedPortfoliosSection extends StatefulWidget {
  const SharedPortfoliosSection({super.key});

  @override
  State<SharedPortfoliosSection> createState() =>
      _SharedPortfoliosSectionState();
}

class _SharedPortfoliosSectionState extends State<SharedPortfoliosSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _mySharedPortfolios = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMySharedPortfolios();
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
              'id': doc.id, // Add document ID to the portfolio data
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
    if (_isLoading) {
      return _buildLoadingSection();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorSection();
    }

    if (_mySharedPortfolios.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return _buildGlassSection(
      title: 'Shared Portfolios',
      theme: theme,
      isDarkMode: isDarkMode,
      children: [
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ..._mySharedPortfolios
            .map((portfolio) => _buildSharedPortfolioItem(portfolio)),
      ],
    );
  }

  Widget _buildLoadingSection() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorSection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _errorMessage,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildGlassSection({
    required String title,
    required ThemeData theme,
    required bool isDarkMode,
    required List<Widget> children,
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
          ...children,
        ],
      ),
    );
  }

  Widget _buildSharedPortfolioItem(Map<String, dynamic> portfolio) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('wallets')
          .doc(portfolio['walletId'])
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: CircularProgressIndicator(),
            title: Text('Loading portfolio...'),
          );
        }

        if (snapshot.hasError) {
          return ListTile(
            leading: const Icon(Icons.error, color: Colors.red),
            title: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return ListTile(
            leading: const Icon(Icons.warning, color: Colors.orange),
            title: const Text('Portfolio not found'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _unsharePortfolio(portfolio['walletId']),
            ),
          );
        }

        final wallet =
            Wallet.fromJson(snapshot.data!.data() as Map<String, dynamic>);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.wallet, size: 32),
            title: Text(
              wallet.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Views: ${portfolio['viewCount'] ?? 0}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Likes: ${portfolio['likes']?.length ?? 0}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _unsharePortfolio(portfolio['walletId']),
            ),
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
          ),
        );
      },
    );
  }

  Future<void> _unsharePortfolio(String walletId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unshare Portfolio'),
        content: const Text('Do you want to stop sharing this portfolio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unshare', style: TextStyle(color: Colors.red)),
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
              const SnackBar(content: Text('Portfolio unshared successfully')),
            );
          }

          _loadMySharedPortfolios();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to unshare: $e')),
          );
        }
      }
    }
  }
}
