import 'package:flutter/material.dart';
import '../../models/wallet_model.dart';

class EditAssetScreen extends StatefulWidget {
  final WalletItem item;
  final Function(WalletItem) onSave;

  const EditAssetScreen({
    super.key,
    required this.item,
    required this.onSave,
  });

  @override
  State<EditAssetScreen> createState() => _EditAssetScreenState();
}

class _EditAssetScreenState extends State<EditAssetScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _buyPriceController;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.item.amount.toString());
    _buyPriceController =
        TextEditingController(text: widget.item.buyPrice.toString());
  }

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
        title: Text('Edit ${widget.item.cryptoName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(widget.item.cryptoImage),
              ),
              title: Text(widget.item.cryptoName),
              subtitle: Text(widget.item.cryptoSymbol.toUpperCase()),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _buyPriceController,
              decoration: InputDecoration(
                labelText: 'Buy Price (USD)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    final updatedItem = widget.item.copyWith(
      amount: double.tryParse(_amountController.text) ?? widget.item.amount,
      buyPrice:
          double.tryParse(_buyPriceController.text) ?? widget.item.buyPrice,
    );
    widget.onSave(updatedItem);
    Navigator.pop(context);
  }
}
