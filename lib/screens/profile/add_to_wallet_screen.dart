import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/crypto_model.dart';
import '../../models/wallet_model.dart';
import '../../services/crypto_service.dart';

class AddToWalletScreen extends StatefulWidget {
  const AddToWalletScreen({super.key});

  @override
  State<AddToWalletScreen> createState() => _AddToWalletScreenState();
}

class _AddToWalletScreenState extends State<AddToWalletScreen> {
  final CryptoService _cryptoService = CryptoService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CryptoModel? _selectedCrypto;
  List<CryptoModel> _allCryptos = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCryptos();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _buyPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadCryptos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final cryptos = await _cryptoService.getCryptoData();
      setState(() {
        _allCryptos = cryptos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load cryptocurrencies: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add to Wallet',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_sharp,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildCryptoDropdown(),
                        const SizedBox(height: 20),
                        _buildAmountField(),
                        const SizedBox(height: 20),
                        _buildBuyPriceField(),
                        const SizedBox(height: 32),
                        _buildAddButton(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'Add New Asset',
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildCryptoDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cryptocurrency',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        // Add a fixed height container to eliminate overflow
        SizedBox(
          height: 50, // Fixed height to contain the dropdown button
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Theme(
              // Override the default dropdown theme locally
              data: Theme.of(context).copyWith(
                // Reduces the dropdown menu density
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CryptoModel>(
                  value: _selectedCrypto,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  // Remove all padding
                  padding: EdgeInsets.zero,
                  // Align items to the start
                  itemHeight: null, // Remove fixed item height
                  // Add validator separately since we're using DropdownButton instead of DropdownButtonFormField
                  hint: const Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Text('Select a cryptocurrency'),
                  ),
                  items: _allCryptos.map((crypto) {
                    return DropdownMenuItem<CryptoModel>(
                      value: crypto,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCryptoImage(crypto),
                            const SizedBox(width: 8),
                            Expanded(child: _buildCryptoInfo(crypto)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCrypto = value;
                      if (_selectedCrypto != null &&
                          _buyPriceController.text.isEmpty) {
                        _buyPriceController.text =
                            _selectedCrypto!.currentPrice.toStringAsFixed(4);
                      }
                    });
                  },
                ),
              ),
            ),
          ),
        ),
        // Add validation message display
        if (_selectedCrypto == null &&
            _formKey.currentState?.validate() == false)
          const Padding(
            padding: EdgeInsets.only(top: 6.0, left: 12.0),
            child: Text(
              'Please select a cryptocurrency',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildCryptoImage(CryptoModel crypto) {
    return Container(
      width: 24, // Smaller size
      height: 24, // Smaller size
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: NetworkImage(crypto.image),
          onError: (_, __) =>
              const Icon(Icons.currency_bitcoin, size: 18), // Smaller icon size
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildCryptoInfo(CryptoModel crypto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Keep column as small as possible
      children: [
        // Use single line for crypto name and symbol to save space
        Text(
          crypto.name,
          style: const TextStyle(fontSize: 13), // Slightly smaller font
          overflow: TextOverflow.ellipsis,
          maxLines: 1, // Force single line
        ),
        Text(
          crypto.symbol.toUpperCase(),
          style: TextStyle(
            fontSize: 11, // Slightly smaller font
            color: Colors.grey.shade600,
          ),
          maxLines: 1, // Force single line
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            hintText: '0.00',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter an amount';
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBuyPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buy Price (USD)',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _buyPriceController,
          decoration: InputDecoration(
            hintText: '0.00',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a buy price';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _saveToWallet,
        style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Add to Wallet', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Future<void> _saveToWallet() async {
    if (!_formKey.currentState!.validate() || _selectedCrypto == null) return;

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final newItem = WalletItem(
        cryptoId: _selectedCrypto!.id,
        cryptoName: _selectedCrypto!.name,
        cryptoSymbol: _selectedCrypto!.symbol,
        cryptoImage: _selectedCrypto!.image,
        amount: double.parse(_amountController.text),
        buyPrice: double.parse(_buyPriceController.text),
      );

      // Wallet ID'sini doğru şekilde al
      final walletId = ModalRoute.of(context)?.settings.arguments as String?;
      if (walletId == null) throw Exception('Wallet ID not provided');

      // Firestore'a ekleme işlemi
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wallets')
          .doc(walletId)
          .update({
        'items': FieldValue.arrayUnion([newItem.toJson()])
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
