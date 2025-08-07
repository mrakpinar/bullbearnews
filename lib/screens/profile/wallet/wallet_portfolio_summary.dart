import 'package:bullbearnews/widgets/profile/wallet_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:bullbearnews/models/crypto_model.dart';
import 'package:bullbearnews/models/wallet_model.dart';

class WalletPortfolioSummary extends StatelessWidget {
  final List<WalletItem> items;
  final List<CryptoModel> allCryptos;
  final VoidCallback onAddToWallet;
  final VoidCallback onShowDetails;

  const WalletPortfolioSummary({
    super.key,
    required this.items,
    required this.allCryptos,
    required this.onAddToWallet,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate portfolio values
    final totalValue = items.fold<double>(0, (sum, item) {
      // Find the corresponding crypto in allCryptos
      final crypto = allCryptos.firstWhere(
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
      return sum + (item.amount * crypto.currentPrice);
    });

    final totalInvestment = items.fold<double>(
        0, (sum, item) => sum + (item.amount * item.buyPrice));
    final totalProfitLoss = totalValue - totalInvestment;
    final totalProfitLossPercentage =
        totalInvestment > 0 ? (totalProfitLoss / totalInvestment) * 100 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        WalletSummaryCard(
          totalPortfolioValue: totalValue,
          totalInvestment: totalInvestment,
          totalProfitLoss: totalProfitLoss,
          totalProfitLossPercentage: totalProfitLossPercentage.toDouble(),
          onAddToWallet: onAddToWallet,
          onShowDetails: onShowDetails,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
