import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/crypto_model.dart';
import '../../models/wallet_model.dart';
import '../../services/crypto_service.dart';

class PortfolioDetailScreen extends StatefulWidget {
  final Wallet wallet;
  final Function() onUpdate;

  const PortfolioDetailScreen({
    super.key,
    required this.wallet,
    required this.onUpdate,
  });

  @override
  State<PortfolioDetailScreen> createState() => _PortfolioDetailScreenState();
}

class _PortfolioDetailScreenState extends State<PortfolioDetailScreen> {
  late Wallet _wallet;

  // Initialize with an empty list instead of using 'late'
  List<WalletItem> _walletItems = [];

  final CryptoService _cryptoService = CryptoService();
  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _wallet = widget.wallet;

    // Safely initialize wallet items from the wallet
    _walletItems = List<WalletItem>.from(_wallet.items);

    _loadData();
  }

  Future<void> _updateItemAmount(int index, double newAmount) async {
    if (newAmount <= 0) {
      _showSnackbar('Amount must be greater than 0', isError: true);
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final item = _walletItems[index];

      // Create updated items list
      List<Map<String, dynamic>> updatedItems =
          _walletItems.map((item) => item.toJson()).toList();
      updatedItems[index]['amount'] = newAmount;

      // Update the Firestore document with the complete items list
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wallets')
          .doc(_wallet.id)
          .update({'items': updatedItems});

      // Update local state
      setState(() {
        _walletItems[index] = item.copyWith(amount: newAmount);
      });

      widget.onUpdate();
      _showSnackbar('Amount updated successfully');
    } catch (e) {
      _showSnackbar('Error updating amount: $e', isError: true);
    }
  }

  Future<void> _removeItem(String cryptoId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Remove the item from local state
      final updatedItems =
          _walletItems.where((item) => item.cryptoId != cryptoId).toList();

      // Convert to JSON format for Firestore
      final updatedItemsJson =
          updatedItems.map((item) => item.toJson()).toList();

      // Update the Firestore document with the updated items list
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wallets')
          .doc(_wallet.id)
          .update({'items': updatedItemsJson});

      setState(() {
        _walletItems = updatedItems;
      });

      widget.onUpdate();
      _showSnackbar('Item removed from portfolio');
    } catch (e) {
      _showSnackbar('Error removing item: $e', isError: true);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _cryptoService.getCryptoData();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('Error loading data: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _walletItems.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _walletItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _walletItems[index];
                    return _buildPortfolioItem(item, index);
                  },
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
          Text(
            'Your portfolio is empty',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add cryptocurrencies to track your investments',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioItem(WalletItem item, int index) {
    return FutureBuilder<List<CryptoModel>>(
      future: _cryptoService.getCryptoData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingCard();
        }

        final crypto = snapshot.data!.firstWhere(
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

        final currentValue = item.amount * crypto.currentPrice;
        final investedValue = item.amount * item.buyPrice;
        final profitLoss = currentValue - investedValue;
        final profitLossPercentage =
            investedValue > 0 ? (profitLoss / investedValue) * 100 : 0;
        final isProfit = profitLoss >= 0;

        return Dismissible(
          key: Key(item.cryptoId),
          direction: DismissDirection.endToStart,
          background: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) => _showDeleteConfirmationDialog(item),
          onDismissed: (direction) => _removeItem(item.cryptoId),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showEditDialog(item, index),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Theme.of(context).cardColor,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              item.cryptoImage,
                              width: 36,
                              height: 36,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.currency_bitcoin),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.cryptoName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.cryptoSymbol.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${currentValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isProfit
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isProfit
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    size: 16,
                                    color: isProfit ? Colors.green : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${profitLossPercentage.toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isProfit ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDetailItem(
                          'Amount',
                          '${item.amount.toStringAsFixed(4)} ${item.cryptoSymbol.toUpperCase()}',
                        ),
                        _buildDetailItem(
                          'Avg Buy Price',
                          '\$${item.buyPrice.toStringAsFixed(4)}',
                        ),
                        _buildDetailItem(
                          'Profit/Loss',
                          '\$${profitLoss.abs().toStringAsFixed(2)}',
                          isProfit: isProfit,
                        ),
                      ],
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

  Widget _buildDetailItem(String title, String value, {bool? isProfit}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isProfit != null
                ? isProfit
                    ? Colors.green
                    : Colors.red
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(
              'Loading asset data...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(WalletItem item) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to remove ${item.cryptoName} from your portfolio?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(WalletItem item, int index) async {
    final amountController = TextEditingController(
      text: item.amount.toStringAsFixed(4),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Amount'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'New Amount',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newAmount = double.tryParse(amountController.text);
              if (newAmount != null && newAmount > 0) {
                await _updateItemAmount(index, newAmount);
                Navigator.pop(context);
              } else {
                _showSnackbar('Please enter a valid amount', isError: true);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
