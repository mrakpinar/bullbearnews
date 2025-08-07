import 'package:flutter/material.dart';
import '../../../../models/crypto_model.dart';
import '../../../../models/price_alert_model.dart';
import '../../../../services/price_alert_service.dart';

class CryptoAlertsDialog extends StatelessWidget {
  final CryptoModel crypto;
  final PriceAlertService priceAlertService;
  final Function(String) onRemoveAlert;

  const CryptoAlertsDialog({
    super.key,
    required this.crypto,
    required this.priceAlertService,
    required this.onRemoveAlert,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alertsStream = priceAlertService.getAlertsForCrypto(crypto.id);

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF393E46) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: _buildDialogHeader(isDark),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: StreamBuilder<List<PriceAlert>>(
          stream: alertsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorState();
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            final alerts = snapshot.data ?? [];
            if (alerts.isEmpty) {
              return _buildEmptyState();
            }

            return _buildAlertsList(alerts, isDark);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Close',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF948979),
              fontFamily: 'DMSerif',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogHeader(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF393E46),
                Color(0xFF948979),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.notifications_active,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Price Alerts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
            fontFamily: 'DMSerif',
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text('Error loading alerts'),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading alerts...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 48,
            color: Color(0xFF948979),
          ),
          SizedBox(height: 16),
          Text(
            'No alerts set yet',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF948979),
              fontFamily: 'DMSerif',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList(List<PriceAlert> alerts, bool isDark) {
    return ListView.builder(
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return _buildAlertListItem(alert, isDark);
      },
    );
  }

  Widget _buildAlertListItem(PriceAlert alert, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: isDark
            ? const Color(0xFF222831).withOpacity(0.5)
            : const Color(0xFFF5F5F5),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: alert.isAbove
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            alert.isAbove ? Icons.trending_up : Icons.trending_down,
            color: alert.isAbove ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          '${alert.cryptoSymbol.toUpperCase()} ${alert.isAbove ? 'above' : 'below'}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
            fontFamily: 'DMSerif',
          ),
        ),
        subtitle: Text(
          '\$${_formatPrice(alert.targetPrice)}',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF948979),
            fontFamily: 'DMSerif',
          ),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.red,
            size: 20,
          ),
          onPressed: () => onRemoveAlert(alert.id),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price.isNaN || price.isInfinite || price < 0) {
      return 'N/A';
    }
    if (price == 0) {
      return '0.00';
    }

    if (price < 1) {
      return price
          .toStringAsFixed(6)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    } else if (price < 1000) {
      return price
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    } else {
      return price.toStringAsFixed(0);
    }
  }
}
