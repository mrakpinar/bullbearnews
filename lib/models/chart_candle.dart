// models/chart_candle.dart
class ChartCandle {
  final int timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  ChartCandle({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory ChartCandle.fromMap(Map<String, dynamic> map) {
    return ChartCandle(
      timestamp: map['timestamp']?.toInt() ?? 0,
      open: map['open']?.toDouble() ?? 0.0,
      high: map['high']?.toDouble() ?? 0.0,
      low: map['low']?.toDouble() ?? 0.0,
      close: map['close']?.toDouble() ?? 0.0,
      volume: map['volume']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
    };
  }

  // Datetime objesi olarak timestamp'i döndür
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  // Mum yeşil mi kırmızı mı?
  bool get isBullish => close > open;

  // Mum gövdesi (body) yüksekliği
  double get bodyHeight => (close - open).abs();

  // Üst gölge (upper shadow) yüksekliği
  double get upperShadowHeight => high - (close > open ? close : open);

  // Alt gölge (lower shadow) yüksekliği
  double get lowerShadowHeight => (close < open ? close : open) - low;

  @override
  String toString() {
    return 'ChartCandle(timestamp: $timestamp, open: $open, high: $high, low: $low, close: $close, volume: $volume)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChartCandle &&
        other.timestamp == timestamp &&
        other.open == open &&
        other.high == high &&
        other.low == low &&
        other.close == close &&
        other.volume == volume;
  }

  @override
  int get hashCode {
    return timestamp.hashCode ^
        open.hashCode ^
        high.hashCode ^
        low.hashCode ^
        close.hashCode ^
        volume.hashCode;
  }
}
