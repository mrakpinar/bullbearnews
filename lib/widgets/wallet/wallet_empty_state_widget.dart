import 'package:bullbearnews/constants/colors.dart';
import 'package:bullbearnews/screens/profile/wallet/add_wallet_screen.dart';
import 'package:flutter/material.dart';

class WalletEmptyStateWidget extends StatelessWidget {
  final bool isDark;
  final VoidCallback loadWallets;
  final VoidCallback loadSharedWallets;

  const WalletEmptyStateWidget({
    super.key,
    required this.isDark,
    required this.loadWallets,
    required this.loadSharedWallets,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.secondary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 64,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Wallets Yet',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.lightText : AppColors.darkText,
                fontFamily: 'DMSerif',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first portfolio to start tracking\nyour crypto investments and watch your\nwealth grow over time',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppColors.lightText.withOpacity(0.7)
                    : AppColors.darkText.withOpacity(0.7),
                fontFamily: 'DMSerif',
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddWalletScreen()),
                  );
                  loadWallets();
                  loadSharedWallets();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(Icons.add_rounded, color: AppColors.whiteText),
                label: Text(
                  'Create Your First Wallet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.whiteText,
                    fontFamily: 'DMSerif',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
