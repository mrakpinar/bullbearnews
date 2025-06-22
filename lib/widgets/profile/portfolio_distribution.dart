import 'package:bullbearnews/models/crypto_model.dart';
import 'package:bullbearnews/models/wallet_model.dart';
import 'package:bullbearnews/providers/theme_provider.dart';
import 'package:bullbearnews/services/crypto_service.dart';
import 'package:bullbearnews/widgets/profile/portfolio_pie_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PortfolioDistribution extends StatefulWidget {
  final List<WalletItem> walletItems;

  const PortfolioDistribution({
    super.key,
    required this.walletItems,
  });

  @override
  State<PortfolioDistribution> createState() => _PortfolioDistributionState();
}

class _PortfolioDistributionState extends State<PortfolioDistribution> {
  final CryptoService _cryptoService = CryptoService();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final theme = Theme.of(context);

    Widget buildGlassSection({
      required String title,
      required ThemeData theme,
      required bool isDarkMode,
      required List<Widget> children,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                Column(children: children),
              ],
            ),
          ),
        ],
      );
    }

    return FutureBuilder<List<CryptoModel>>(
      future: _cryptoService.getCryptoData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isDarkMode
                    ? const Color(0xFF393E46).withOpacity(0.7)
                    : const Color(0xFFF5F5F5).withOpacity(0.7),
              ),
              child: const CircularProgressIndicator(),
            ),
          );
        }
        return buildGlassSection(
          title: 'Portfolio Distribution',
          theme: theme,
          isDarkMode: isDarkMode,
          children: [
            PortfolioPieChart(
              walletItems: widget.walletItems,
              allCryptos: snapshot.data!,
            ),
          ],
        );
      },
    );
  }
}
