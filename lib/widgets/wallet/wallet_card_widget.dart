import 'package:bullbearnews/models/crypto_model.dart';
import 'package:bullbearnews/models/wallet_model.dart';
import 'package:bullbearnews/services/crypto_service.dart';
import 'package:bullbearnews/constants/colors.dart';
import 'package:flutter/material.dart';

class WalletCardWidget extends StatelessWidget {
  final Wallet wallet;
  final bool isShared;
  final bool isDark;
  final VoidCallback onSharePressed;
  final VoidCallback onTap;
  final CryptoService cryptoService;

  const WalletCardWidget({
    super.key,
    required this.wallet,
    required this.isShared,
    required this.isDark,
    required this.onSharePressed,
    required this.onTap,
    required this.cryptoService,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FutureBuilder<List<CryptoModel>>(
          future: cryptoService.getCryptoData(),
          builder: (context, snapshot) {
            final isLoading = !snapshot.hasData;
            final currentValue =
                isLoading ? 0 : wallet.calculateCurrentValue(snapshot.data!);
            final investmentValue = wallet.totalInvestmentValue;
            final profitLoss = currentValue - investmentValue;
            final isProfit = profitLoss >= 0;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isShared
                      ? Colors.green.withOpacity(0.5)
                      : (isDark
                          ? AppColors.lightText.withOpacity(0.1)
                          : AppColors.darkText.withOpacity(0.1)),
                  width: isShared ? 2 : 1,
                ),
              ),
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Wallet Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.2),
                                AppColors.secondary.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: AppColors.secondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Wallet Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                wallet.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.lightText
                                      : AppColors.darkText,
                                  fontFamily: 'DMSerif',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.pie_chart_outline_rounded,
                                    size: 16,
                                    color: isDark
                                        ? AppColors.lightText.withOpacity(0.6)
                                        : AppColors.darkText.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${wallet.items.length} assets',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? AppColors.lightText.withOpacity(0.7)
                                          : AppColors.darkText.withOpacity(0.7),
                                      fontFamily: 'DMSerif',
                                    ),
                                  ),
                                  if (isShared) ...[
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.green.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.public,
                                            size: 12,
                                            color: Colors.green.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Shared',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green.shade600,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'DMSerif',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Share Button
                        if (!isShared)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue, Colors.blue.shade600],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: onSharePressed,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.share_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Divider
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            (isDark ? AppColors.lightText : AppColors.darkText)
                                .withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Value Display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Portfolio Value',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.lightText.withOpacity(0.6)
                                    : AppColors.darkText.withOpacity(0.6),
                                fontFamily: 'DMSerif',
                              ),
                            ),
                            const SizedBox(height: 4),
                            isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.secondary,
                                    ),
                                  )
                                : Text(
                                    '\$${currentValue.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDark ? Colors.amber : Colors.blue,
                                      fontFamily: 'DMSerif',
                                    ),
                                  ),
                          ],
                        ),
                        if (!isLoading)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: (isProfit ? Colors.green : Colors.red)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (isProfit ? Colors.green : Colors.red)
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isProfit
                                      ? Icons.trending_up_rounded
                                      : Icons.trending_down_rounded,
                                  size: 16,
                                  color: isProfit ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${isProfit ? '+' : ''}\$${profitLoss.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isProfit ? Colors.green : Colors.red,
                                    fontFamily: 'DMSerif',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
