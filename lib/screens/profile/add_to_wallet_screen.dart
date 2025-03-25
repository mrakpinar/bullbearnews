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
  CryptoModel? _selectedCrypto;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _buyPriceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add New Asset',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              // Crypto Selection
              Column(
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
                      isExpanded: true, // Bu satır çok önemli
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      icon: const Icon(Icons.arrow_drop_down),
                      selectedItemBuilder: (BuildContext context) {
                        return widget.cryptos.map<Widget>((CryptoModel item) {
                          return Container(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                if (_selectedCrypto != null)
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        image: NetworkImage(
                                            _selectedCrypto!.image),
                                        onError: (_, __) => const Icon(
                                            Icons.currency_bitcoin,
                                            size: 24),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedCrypto != null
                                        ? '${_selectedCrypto!.name} (${_selectedCrypto!.symbol.toUpperCase()})'
                                        : 'Select a cryptocurrency',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      items: widget.cryptos.map((crypto) {
                        return DropdownMenuItem<CryptoModel>(
                          value: crypto,
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage(crypto.image),
                                    onError: (_, __) => const Icon(
                                        Icons.currency_bitcoin,
                                        size: 24),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.6,
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
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCrypto = value;
                          if (_selectedCrypto != null &&
                              _buyPriceController.text.isEmpty) {
                            _buyPriceController.text = _selectedCrypto!
                                .currentPrice
                                .toStringAsFixed(4);
                          }
                        });
                      },
                      validator: (value) => value == null
                          ? 'Please select a cryptocurrency'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Amount Input
              Column(
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Buy Price Input
              Column(
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
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
              ),
              const SizedBox(height: 32),
              // Add Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveToWallet,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Add to Wallet',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveToWallet() async {
    if (_formKey.currentState!.validate() && _selectedCrypto != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final List<String> walletItemsJson =
            prefs.getStringList('walletItems') ?? [];

        final newItem = WalletItem(
          cryptoId: _selectedCrypto!.id,
          cryptoName: _selectedCrypto!.name,
          cryptoSymbol: _selectedCrypto!.symbol,
          cryptoImage: _selectedCrypto!.image,
          amount: double.parse(_amountController.text),
          buyPrice: double.parse(_buyPriceController.text),
        );

        walletItemsJson.add(json.encode(newItem.toJson()));
        await prefs.setStringList('walletItems', walletItemsJson);

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving to wallet: $e'),
              backgroundColor: Colors.red,
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
