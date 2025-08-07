import 'dart:async';
import 'package:bullbearnews/models/chart_candle.dart';
import 'package:bullbearnews/services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CryptoChartWidget extends StatefulWidget {
  final List<ChartCandle> candles;
  final String timeFrame;
  final Function(String, bool)? onIndicatorToggled;
  final bool initialRSI;
  final bool initialMACD;
  final bool initialVolume;

  const CryptoChartWidget({
    super.key,
    required this.candles,
    required this.timeFrame,
    this.onIndicatorToggled,
    required this.initialRSI,
    required this.initialMACD,
    required this.initialVolume,
  });

  @override
  State<CryptoChartWidget> createState() => _CryptoChartWidgetState();
}

class _CryptoChartWidgetState extends State<CryptoChartWidget> {
  late List<ChartCandle> _candles;
  late Timer _refreshTimer;
  late bool _showRSI;
  late bool _showMACD;
  late bool _showVolume;

  @override
  void initState() {
    super.initState();
    _candles = widget.candles;
    _showRSI = widget.initialRSI;
    _showMACD = widget.initialMACD;
    _showVolume = widget.initialVolume;
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          _candles = [...widget.candles];
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(CryptoChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.candles != oldWidget.candles) {
      setState(() {
        _candles = widget.candles;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final gridColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    AnalyticsService.calculateTechnicalIndicators(_candles);
    final rsiValues = _calculateRSIValues(_candles);
    final macdValues = _calculateMACDValues(_candles);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main price chart
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'BTC/USDT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Price Chart (${widget.timeFrame})',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 250,
                  child: SfCartesianChart(
                    backgroundColor: Colors.transparent,
                    plotAreaBackgroundColor: Colors.transparent,
                    margin: EdgeInsets.zero,
                    legend: Legend(
                      isVisible: true,
                      position: LegendPosition.top,
                      textStyle: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                      ),
                      overflowMode: LegendItemOverflowMode.wrap,
                    ),
                    tooltipBehavior: TooltipBehavior(
                      enable: true,
                      shared: true,
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      textStyle: TextStyle(color: textColor),
                      borderColor: theme.primaryColor,
                      borderWidth: 1,
                    ),
                    crosshairBehavior: CrosshairBehavior(
                      enable: true,
                      activationMode: ActivationMode.singleTap,
                      lineType: CrosshairLineType.both,
                      lineColor: theme.primaryColor.withOpacity(0.5),
                      lineWidth: 1,
                    ),
                    zoomPanBehavior: ZoomPanBehavior(
                      enablePinching: true,
                      enablePanning: true,
                      enableDoubleTapZooming: true,
                      zoomMode: ZoomMode.x,
                      enableMouseWheelZooming: true,
                    ),
                    primaryXAxis: DateTimeAxis(
                      intervalType: _getIntervalType(widget.timeFrame),
                      edgeLabelPlacement: EdgeLabelPlacement.shift,
                      enableAutoIntervalOnZooming: true,
                      majorGridLines: MajorGridLines(
                        width: 0.5,
                        color: gridColor,
                      ),
                      axisLine: AxisLine(color: gridColor, width: 0.5),
                      labelStyle: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 10,
                      ),
                    ),
                    primaryYAxis: NumericAxis(
                      opposedPosition: true,
                      majorGridLines: MajorGridLines(
                        width: 0.5,
                        color: gridColor,
                      ),
                      axisLine: AxisLine(color: gridColor, width: 0.5),
                      labelStyle: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 10,
                      ),
                      numberFormat: NumberFormat.currency(
                        symbol: '\$',
                        decimalDigits: 2,
                      ),
                    ),
                    series: <CartesianSeries>[
                      CandleSeries<ChartCandle, DateTime>(
                        name: 'Price',
                        dataSource: _candles,
                        xValueMapper: (ChartCandle data, _) =>
                            DateTime.fromMillisecondsSinceEpoch(data.timestamp),
                        lowValueMapper: (ChartCandle data, _) => data.low,
                        highValueMapper: (ChartCandle data, _) => data.high,
                        openValueMapper: (ChartCandle data, _) => data.open,
                        closeValueMapper: (ChartCandle data, _) => data.close,
                        enableTooltip: true,
                        bearColor: const Color(0xFFEF5350),
                        bullColor: const Color(0xFF26A69A),
                      ),
                      LineSeries<ChartCandle, DateTime>(
                        name: 'SMA 20',
                        dataSource: _candles,
                        xValueMapper: (ChartCandle data, _) =>
                            DateTime.fromMillisecondsSinceEpoch(data.timestamp),
                        yValueMapper: (ChartCandle data, _) =>
                            AnalyticsService.calculateSMA(
                                _candles.map((c) => c.close).toList(), 20),
                        color: const Color(0xFF2196F3),
                        width: 2,
                      ),
                      LineSeries<ChartCandle, DateTime>(
                        name: 'SMA 50',
                        dataSource: _candles,
                        xValueMapper: (ChartCandle data, _) =>
                            DateTime.fromMillisecondsSinceEpoch(data.timestamp),
                        yValueMapper: (ChartCandle data, _) =>
                            AnalyticsService.calculateSMA(
                                _candles.map((c) => c.close).toList(), 50),
                        color: const Color(0xFF9C27B0),
                        width: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Indicator toggles
          _buildIndicatorToggles(isDark),

          // Indicators
          if (_showRSI) _buildRSIChart(rsiValues, isDark),
          if (_showMACD) _buildMACDChart(macdValues, isDark),
          if (_showVolume) _buildVolumeChart(isDark),
        ],
      ),
    );
  }

  Widget _buildIndicatorToggles(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildToggleButton('RSI', _showRSI, isDark, () {
            setState(() => _showRSI = !_showRSI);
            widget.onIndicatorToggled?.call('RSI', _showRSI);
          }),
          _buildToggleButton('MACD', _showMACD, isDark, () {
            setState(() => _showMACD = !_showMACD);
            widget.onIndicatorToggled?.call('MACD', _showMACD);
          }),
          _buildToggleButton('Volume', _showVolume, isDark, () {
            setState(() => _showVolume = !_showVolume);
            widget.onIndicatorToggled?.call('Volume', _showVolume);
          }),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
      String text, bool isActive, bool isDark, VoidCallback onPressed) {
    return ChoiceChip(
      label: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color:
              isActive ? Colors.white : (isDark ? Colors.white : Colors.black),
        ),
      ),
      selected: isActive,
      onSelected: (selected) => onPressed(),
      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _buildRSIChart(List<Map<String, dynamic>> rsiValues, bool isDark) {
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final gridColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        height: 120,
        child: SfCartesianChart(
          backgroundColor: Colors.transparent,
          plotAreaBackgroundColor: Colors.transparent,
          margin: EdgeInsets.zero,
          primaryXAxis: DateTimeAxis(
            intervalType: _getIntervalType(widget.timeFrame),
            isVisible: false,
          ),
          primaryYAxis: NumericAxis(
            minimum: 0,
            maximum: 100,
            interval: 25,
            majorGridLines: MajorGridLines(
              width: 0.5,
              color: gridColor,
            ),
            axisLine: AxisLine(color: gridColor, width: 0.5),
            labelStyle: TextStyle(
              color: secondaryTextColor,
              fontSize: 10,
            ),
          ),
          series: <LineSeries>[
            LineSeries<Map<String, dynamic>, DateTime>(
              dataSource: rsiValues,
              xValueMapper: (data, _) =>
                  DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
              yValueMapper: (data, _) => data['rsi'] as double,
              name: 'RSI (14)',
              color: const Color(0xFFFFA726),
              width: 2,
            ),
            LineSeries<Map<String, dynamic>, DateTime>(
              dataSource: rsiValues,
              xValueMapper: (data, _) =>
                  DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
              yValueMapper: (data, _) => 70,
              name: 'Overbought',
              color: const Color(0xFFEF5350),
              width: 1,
              dashArray: const [5, 5],
            ),
            LineSeries<Map<String, dynamic>, DateTime>(
              dataSource: rsiValues,
              xValueMapper: (data, _) =>
                  DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
              yValueMapper: (data, _) => 30,
              name: 'Oversold',
              color: const Color(0xFF66BB6A),
              width: 1,
              dashArray: const [5, 5],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMACDChart(List<Map<String, dynamic>> macdValues, bool isDark) {
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final gridColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        height: 120,
        child: SfCartesianChart(
          backgroundColor: Colors.transparent,
          plotAreaBackgroundColor: Colors.transparent,
          margin: EdgeInsets.zero,
          primaryXAxis: DateTimeAxis(
            intervalType: _getIntervalType(widget.timeFrame),
            isVisible: false,
          ),
          primaryYAxis: NumericAxis(
            majorGridLines: MajorGridLines(
              width: 0.5,
              color: gridColor,
            ),
            axisLine: AxisLine(color: gridColor, width: 0.5),
            labelStyle: TextStyle(
              color: secondaryTextColor,
              fontSize: 10,
            ),
          ),
          series: <CartesianSeries>[
            ColumnSeries<Map<String, dynamic>, DateTime>(
              dataSource: macdValues,
              xValueMapper: (data, _) =>
                  DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
              yValueMapper: (data, _) => data['histogram'] as double,
              name: 'MACD Hist',
              pointColorMapper: (data, _) => (data['histogram'] as double) >= 0
                  ? const Color(0xFF66BB6A)
                  : const Color(0xFFEF5350),
            ),
            LineSeries<Map<String, dynamic>, DateTime>(
              dataSource: macdValues,
              xValueMapper: (data, _) =>
                  DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
              yValueMapper: (data, _) => data['macd'] as double,
              name: 'MACD',
              color: const Color(0xFF2196F3),
              width: 2,
            ),
            LineSeries<Map<String, dynamic>, DateTime>(
              dataSource: macdValues,
              xValueMapper: (data, _) =>
                  DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
              yValueMapper: (data, _) => (data['signal'] as num).toDouble(),
              name: 'Signal',
              color: const Color(0xFF9C27B0),
              width: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeChart(bool isDark) {
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final gridColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        height: 100,
        child: SfCartesianChart(
          backgroundColor: Colors.transparent,
          plotAreaBackgroundColor: Colors.transparent,
          margin: EdgeInsets.zero,
          primaryXAxis: DateTimeAxis(
            intervalType: _getIntervalType(widget.timeFrame),
            majorGridLines: MajorGridLines(
              width: 0.5,
              color: gridColor,
            ),
            axisLine: AxisLine(color: gridColor, width: 0.5),
            labelStyle: TextStyle(
              color: secondaryTextColor,
              fontSize: 10,
            ),
          ),
          primaryYAxis: NumericAxis(
            isVisible: false,
            majorGridLines: MajorGridLines(
              width: 0.5,
              color: gridColor,
            ),
          ),
          series: <CartesianSeries>[
            ColumnSeries<ChartCandle, DateTime>(
              dataSource: _candles,
              xValueMapper: (ChartCandle data, _) =>
                  DateTime.fromMillisecondsSinceEpoch(data.timestamp),
              yValueMapper: (ChartCandle data, _) => data.volume,
              name: 'Volume',
              pointColorMapper: (ChartCandle data, _) => data.close >= data.open
                  ? const Color(0xFF66BB6A).withOpacity(0.7)
                  : const Color(0xFFEF5350).withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _calculateRSIValues(List<ChartCandle> candles) {
    final closes = candles.map((c) => c.close).toList();
    final List<Map<String, dynamic>> rsiValues = [];

    for (int i = 14; i < candles.length; i++) {
      final window = closes.sublist(i - 14, i);
      final rsi = AnalyticsService.calculateRSI(window, 14);
      rsiValues.add({
        'timestamp': candles[i].timestamp,
        'rsi': rsi,
      });
    }

    return rsiValues;
  }

  List<Map<String, dynamic>> _calculateMACDValues(List<ChartCandle> candles) {
    final closes = candles.map((c) => c.close).toList();
    final List<Map<String, dynamic>> macdValues = [];

    final ema12 = _calculateEMA(closes, 12);
    final ema26 = _calculateEMA(closes, 26);

    final minLength = ema12.length < ema26.length ? ema12.length : ema26.length;

    for (int i = 0; i < minLength; i++) {
      if (i >= 25 && i < candles.length) {
        final macd = ema12[i] - ema26[i];
        final signal =
            i >= 33 ? _calculateEMA(ema12.sublist(i - 8, i + 1), 9).last : 0;
        final histogram = macd - signal;

        macdValues.add({
          'timestamp': candles[i].timestamp,
          'macd': macd,
          'signal': signal,
          'histogram': histogram,
        });
      }
    }

    return macdValues;
  }

  List<double> _calculateEMA(List<double> prices, int period) {
    final List<double> ema = [];
    final double multiplier = 2 / (period + 1);

    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += prices[i];
    }
    ema.add(sum / period);

    for (int i = period; i < prices.length; i++) {
      ema.add((prices[i] - ema.last) * multiplier + ema.last);
    }

    return ema;
  }

  DateTimeIntervalType _getIntervalType(String tf) {
    switch (tf) {
      case '1m':
      case '5m':
      case '15m':
        return DateTimeIntervalType.minutes;
      case '1h':
      case '4h':
        return DateTimeIntervalType.hours;
      case '1d':
        return DateTimeIntervalType.days;
      default:
        return DateTimeIntervalType.auto;
    }
  }
}
