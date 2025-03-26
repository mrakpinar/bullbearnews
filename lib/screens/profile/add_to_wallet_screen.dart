import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/crypto_model.dart';
import '../../models/wallet_model.dart';

class AddToWalletScreen extends StatefulWidget {
  final List<CryptoModel> cryptos;

  const AddToWalletScreen({super.key, required this.cryptos});

  @override
  State<AddToWalletScreen> createState() => _AddToWalletScreenState();
}

class _AddToWalletScreenState extends State<AddToWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _buyPriceController = TextEditingController();
  CryptoModel? _selectedCrypto;

  @override
  void dispose() {
    _amountController.dispose();
    _buyPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Wallet'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<CryptoModel>(
            value: _selectedCrypto,
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            icon: const Icon(Icons.arrow_drop_down),
            hint: const Text('Select a cryptocurrency'),
            items: widget.cryptos.map((crypto) {
              return DropdownMenuItem<CryptoModel>(
                value: crypto,
                child: Row(
                  children: [
                    _buildCryptoImage(crypto),
                    const SizedBox(width: 12),
                    _buildCryptoInfo(crypto),
                  ],
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
            validator: (value) =>
                value == null ? 'Please select a cryptocurrency' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCryptoImage(CryptoModel crypto) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: NetworkImage(crypto.image),
          onError: (_, __) => const Icon(Icons.currency_bitcoin, size: 24),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildCryptoInfo(CryptoModel crypto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: Text(
            crypto.name,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          crypto.symbol.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
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
      final prefs = await SharedPreferences.getInstance();
      final walletItems = prefs.getStringList('walletItems') ?? [];

      final newItem = WalletItem(
        cryptoId: _selectedCrypto!.id,
        cryptoName: _selectedCrypto!.name,
        cryptoSymbol: _selectedCrypto!.symbol,
        cryptoImage: _selectedCrypto!.image,
        amount: double.parse(_amountController.text),
        buyPrice: double.parse(_buyPriceController.text),
      );

      walletItems.add(json.encode(newItem.toJson()));
      await prefs.setStringList('walletItems', walletItems);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}
