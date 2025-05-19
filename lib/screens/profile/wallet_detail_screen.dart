import 'package:bullbearnews/models/wallet_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_to_wallet_screen.dart';

class WalletDetailScreen extends StatefulWidget {
  final Wallet wallet;
  final Function() onUpdate;

  const WalletDetailScreen({
    super.key,
    required this.wallet,
    required this.onUpdate,
  });

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  late Wallet _wallet;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _wallet = widget.wallet;
  }

  Future<void> _addToWallet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddToWalletScreen(),
        settings: RouteSettings(arguments: _wallet.id), // Wallet ID'sini geç
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

      setState(() {
        _wallet = Wallet.fromJson(doc.data()!).copyWith(id: doc.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading wallet: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_wallet.name, style: const TextStyle(fontSize: 20)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_sharp, size: 30),
            tooltip: 'Add Asset',
            onPressed: _addToWallet,
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red[500], size: 30),
            tooltip: 'Delete Wallet',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Wallet'),
                  content: const Text(
                      'Are you sure you want to delete this wallet? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
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
        ],
      ),
      body: _wallet.items.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: _wallet.items.length,
              itemBuilder: (context, index) {
                final item = _wallet.items[index];
                return InkWell(
                  onTap: () {},
                  child: Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Asset'),
                              content: const Text(
                                  'Are you sure you want to delete this asset from your wallet?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                    },
                    onDismissed: (direction) async {
                      // Remove the item from the wallet
                      setState(() {
                        _wallet.items.removeAt(index);
                      });
                      // Optionally, update Firestore here if needed
                      await _firestore
                          .collection('users')
                          .doc(_auth.currentUser!.uid)
                          .collection('wallets')
                          .doc(_wallet.id)
                          .update({
                        'items': _wallet.items.map((e) => e.toJson()).toList(),
                      });
                      widget.onUpdate();
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete,
                          color: Colors.white, size: 32),
                    ),
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: Colors.grey.withOpacity(0.2),
                      child: _buildWalletItem(item),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wallet,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[500]),
          const SizedBox(height: 8),
          const Text('This wallet is empty',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[200],
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              shadowColor: Theme.of(context).primaryColor.withOpacity(0.5),
              elevation: 4,
            ),
            onPressed: _addToWallet,
            child: Text('Add Assets',
                style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletItem(WalletItem item) {
    return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.transparent,
          child: item.cryptoImage.isEmpty
              ? const Icon(Icons.question_mark, size: 24)
              : ClipOval(
                  child: Image.network(
                    item.cryptoImage,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error, size: 24);
                    },
                  ),
                ),
        ),
        title: Text(item.cryptoName),
        subtitle: Text('${item.amount} ${item.cryptoSymbol.toUpperCase()}',
            style: const TextStyle(fontSize: 16)),
        trailing: Text(
          '\$${(item.amount * item.buyPrice).toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ));
  }
}
