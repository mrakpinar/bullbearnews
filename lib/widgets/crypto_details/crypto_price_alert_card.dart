// widgets/crypto_price_alert_card.dart
import 'package:flutter/material.dart';
import '../../../../models/crypto_model.dart';
import '../../../../models/price_alert_model.dart';

class CryptoPriceAlertCard extends StatelessWidget {
  final CryptoModel crypto;
  final TextEditingController priceAlertController;
  final String selectedAlertType;
  final Stream<List<PriceAlert>> priceAlertsStream;
  final ValueChanged<String> onAlertTypeChanged;
  final VoidCallback onAddAlert;

  const CryptoPriceAlertCard({
    super.key,
    required this.crypto,
    required this.priceAlertController,
    required this.selectedAlertType,
    required this.priceAlertsStream,
    required this.onAlertTypeChanged,
    required this.onAddAlert,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF393E46) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF948979).withOpacity(0.2)
              : const Color(0xFFE0E0E0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 20),
            _buildAlertTypeDropdown(isDark),
            const SizedBox(height: 16),
            _buildPriceInput(isDark),
            const SizedBox(height: 16),
            _buildAddAlertButton(),
            const SizedBox(height: 12),
            const Text(
              'You will be notified when the price reaches your target.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF948979),
                fontFamily: 'DMSerif',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Price Alerts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
                fontFamily: 'DMSerif',
              ),
            ),
          ],
        ),
        StreamBuilder<List<PriceAlert>>(
          stream: priceAlertsStream,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF948979).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${snapshot.data!.length}',
                  style: const TextStyle(
                    color: Color(0xFF948979),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }

  Widget _buildAlertTypeDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF222831).withOpacity(0.5)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF948979).withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedAlertType,
          dropdownColor: isDark ? const Color(0xFF393E46) : Colors.white,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
            fontFamily: 'DMSerif',
          ),
          items: const [
            DropdownMenuItem(
              value: 'above',
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.green, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Above Target Price',
                    style: TextStyle(
                      color: Colors.green,
                      fontFamily: 'DMSerif',
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'below',
              child: Row(
                children: [
                  Icon(Icons.trending_down, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Below Target Price',
                    style: TextStyle(
                      color: Colors.red,
                      fontFamily: 'DMSerif',
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onAlertTypeChanged(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPriceInput(bool isDark) {
    return TextField(
      controller: priceAlertController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
        fontFamily: 'DMSerif',
      ),
      decoration: InputDecoration(
        labelText: 'Target Price',
        labelStyle: const TextStyle(
          color: Color(0xFF948979),
          fontFamily: 'DMSerif',
        ),
        prefixText: '\$',
        prefixStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF948979),
        ),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF222831).withOpacity(0.5)
            : const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF948979).withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF948979),
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildAddAlertButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onAddAlert,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF948979),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_alert,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Set Price Alert',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'DMSerif',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
