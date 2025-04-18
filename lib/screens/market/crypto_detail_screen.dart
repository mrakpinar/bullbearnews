import 'package:bullbearnews/models/price_alert_model.dart';
import 'package:bullbearnews/screens/market/trading_view_chart.dart';
import 'package:bullbearnews/services/price_alert_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/crypto_model.dart';

class CryptoDetailScreen extends StatefulWidget {
  final CryptoModel crypto;

  const CryptoDetailScreen({super.key, required this.crypto});

  @override
  State<CryptoDetailScreen> createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen> {
  final TextEditingController _priceAlertController = TextEditingController();
  final PriceAlertService _priceAlertService = PriceAlertService();
  late Stream<List<PriceAlert>> _priceAlertsStream;
  late CryptoModel _crypto;
  Set<String> _favoriteCryptos = {};
  String _selectedAlertType = 'above';

  @override
  void initState() {
    super.initState();
    _crypto = widget.crypto;
    _priceAlertController.text = _crypto.currentPrice.toString();

    debugPrint('Loading alerts for crypto: ${_crypto.id}');
    _priceAlertsStream = _priceAlertService.getAlertsForCrypto(_crypto.id)
      ..listen((alerts) {
        debugPrint('Alerts updated: ${alerts.length} items');
        for (var alert in alerts) {
          debugPrint('Alert: ${alert.cryptoSymbol} - \$${alert.targetPrice}');
        }
      });

    _loadFavorites();
  }

  @override
  void dispose() {
    _priceAlertController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteCryptos =
          Set<String>.from(prefs.getStringList('favoriteCryptos') ?? []);
      _crypto.isFavorite = _favoriteCryptos.contains(_crypto.id);
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoriteCryptos', _favoriteCryptos.toList());
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _crypto.isFavorite = !_crypto.isFavorite;
      if (_crypto.isFavorite) {
        _favoriteCryptos.add(_crypto.id);
      } else {
        _favoriteCryptos.remove(_crypto.id);
      }
    });
    await _saveFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = _crypto.priceChangePercentage24h >= 0;
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(isPositive, theme),
                  const SizedBox(height: 16),
                  _buildPriceChart(),
                  const SizedBox(height: 16),
                  _buildPriceAlertCard(theme),
                  const SizedBox(height: 16),
                  _buildMarketDetailsCard(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _crypto.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 72, bottom: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.1),
              ],
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _crypto.isFavorite ? Icons.star : Icons.star_border,
            color: _crypto.isFavorite ? Colors.amber : Colors.white,
          ),
          onPressed: _toggleFavorite,
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () => _showAlertsDialog(context),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(bool isPositive, ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Hero(
                  tag: 'crypto-${_crypto.id}',
                  child: CachedNetworkImage(
                    imageUrl: _crypto.image,
                    width: 60,
                    height: 60,
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.currency_bitcoin,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _crypto.symbol.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _crypto.name,
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Price',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${_formatPrice(_crypto.currentPrice)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}${_crypto.priceChangePercentage24h.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
  }

  Widget _buildPriceChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Price Chart',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildTimeframeSelector(),
              ],
            ),
            const SizedBox(height: 16),
            TradingViewChart(
              symbol: _crypto.symbol,
              theme: 'dark',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceAlertCard(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Price Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                StreamBuilder<List<PriceAlert>>(
                  stream: _priceAlertsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return TextButton(
                        onPressed: () => _showAlertsDialog(context),
                        child: Text(
                          'Available Alerts (${snapshot.data!.length})',
                          style: TextStyle(
                            color: theme.primaryColor,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _buildAlertTypeDropdown(),
                const SizedBox(height: 16),
                TextField(
                  controller: _priceAlertController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Target Price',
                    prefixText: '\$',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addPriceAlert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Set Price Alert',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedAlertType,
          items: [
            DropdownMenuItem(
              value: 'above',
              child: Row(
                children: [
                  const Icon(Icons.arrow_upward, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  const Text('Above'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'below',
              child: Row(
                children: [
                  const Icon(Icons.arrow_downward, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  const Text('Below'),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedAlertType = value!;
            });
          },
        ),
      ),
    );
  }

  Future<void> _addPriceAlert() async {
    double? alertPrice = double.tryParse(_priceAlertController.text);

    if (alertPrice == null) {
      _showErrorSnackBar('Please enter a valid price');
      return;
    }

    double currentPrice = _crypto.currentPrice;

    if (_selectedAlertType == 'above' && alertPrice <= currentPrice) {
      _showErrorSnackBar('Target price must be higher than current price');
      return;
    }

    if (_selectedAlertType == 'below' && alertPrice >= currentPrice) {
      _showErrorSnackBar('Target price must be lower than current price');
      return;
    }

    final newAlert = PriceAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cryptoId: _crypto.id,
      cryptoSymbol: _crypto.symbol,
      targetPrice: alertPrice,
      isAbove: _selectedAlertType == 'above',
      createdAt: DateTime.now(),
    );

    try {
      await _priceAlertService.addAlert(newAlert);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_crypto.symbol.toUpperCase()} for ${_selectedAlertType == 'above' ? 'above' : 'below'} alarm set: \$${_formatPrice(alertPrice)}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to save alert: $e');
    }
  }

  void _showAlertsDialog(BuildContext context) {
    // Dialog için yeni bir stream oluştur
    final alertsStream = _priceAlertService.getAlertsForCrypto(_crypto.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Price Alerts'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300, // Sabit bir yükseklik ver
          child: StreamBuilder<List<PriceAlert>>(
            stream: alertsStream,
            builder: (context, snapshot) {
              // Debug mesajları
              debugPrint(
                  'Dialog StreamBuilder state: ${snapshot.connectionState}');
              debugPrint('Dialog StreamBuilder hasData: ${snapshot.hasData}');
              debugPrint('Dialog StreamBuilder hasError: ${snapshot.hasError}');

              if (snapshot.hasError) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                  ],
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
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

              final alerts = snapshot.data ?? [];
              if (alerts.isEmpty) {
                return const Center(child: Text('No alerts set yet'));
              }

              return ListView.builder(
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return ListTile(
                    leading: Icon(
                      alert.isAbove ? Icons.arrow_upward : Icons.arrow_downward,
                      color: alert.isAbove ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      '${alert.cryptoSymbol.toUpperCase()} ${alert.isAbove ? 'when above' : 'when below'}',
                    ),
                    subtitle: Text('\$${_formatPrice(alert.targetPrice)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removeAlert(alert.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final period in ['1D', '1W', '1M', '1Y', 'All'])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: period == '1M' ? Colors.blue : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {},
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 12,
                      color: period == '1M' ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketDetailsCard(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Market Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildStatItem('Market Cap',
                    '\$${_formatNumber(_crypto.marketCap)}', theme),
                _buildStatItem('24H Volume',
                    '\$${_formatNumber(_crypto.totalVolume)}', theme),
                _buildStatItem(
                    'All-Time High', '\$${_formatPrice(_crypto.ath)}', theme),
                _buildStatItem(
                    'All-Time Low', '\$${_formatPrice(_crypto.atl)}', theme),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildSupplySection()
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplySection() {
    final circulating = widget.crypto.circulatingSupply;
    // Burada totalVolume yerine totalSupply kullanılmış olmalı
    final total = widget.crypto.totalVolume; // totalVolume değil
    final percentCirculating = (circulating / total * 100).clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Supply',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Circulating Supply',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '${_formatNumber(circulating)} ${_crypto.symbol.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Supply',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    _formatNumber(total),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: percentCirculating / 100,
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 4),
        Text(
          '${percentCirculating.toStringAsFixed(1)}% of total supply in circulation',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    if (number >= 1e9) return '${(number / 1e9).toStringAsFixed(2)}B';
    if (number >= 1e6) return '${(number / 1e6).toStringAsFixed(2)}M';
    if (number >= 1e3) return '${(number / 1e3).toStringAsFixed(2)}K';
    return number.toStringAsFixed(2);
  }

  String _formatPrice(double price) {
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

  Future<void> _removeAlert(String alertId) async {
    try {
      await _priceAlertService.removeAlert(alertId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert removed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to remove alert: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
