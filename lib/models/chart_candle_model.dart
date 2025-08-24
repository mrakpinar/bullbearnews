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
      open: (map['open'] ?? 0).toDouble(),
      high: (map['high'] ?? 0).toDouble(),
      low: (map['low'] ?? 0).toDouble(),
      close: (map['close'] ?? 0).toDouble(),
      volume: (map['volume'] ?? 0).toDouble(),
    );
  }

  factory ChartCandle.fromJson(Map<String, dynamic> json) {
    return ChartCandle(
      timestamp: json['timestamp']?.toInt() ?? 0,
      open: (json['open'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      close: (json['close'] ?? 0).toDouble(),
      volume: (json['volume'] ?? 0).toDouble(),
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

  Map<String, dynamic> toJson() {
    return toMap();
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  @override
  String toString() {
    return 'ChartCandle{timestamp: $timestamp, open: $open, high: $high, low: $low, close: $close, volume: $volume}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartCandle &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          open == other.open &&
          high == other.high &&
          low == other.low &&
          close == other.close &&
          volume == other.volume;

  @override
  int get hashCode =>
      timestamp.hashCode ^
      open.hashCode ^
      high.hashCode ^
      low.hashCode ^
      close.hashCode ^
      volume.hashCode;

  ChartCandle copyWith({
    int? timestamp,
    double? open,
    double? high,
    double? low,
    double? close,
    double? volume,
  }) {
    return ChartCandle(
      timestamp: timestamp ?? this.timestamp,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      close: close ?? this.close,
      volume: volume ?? this.volume,
    );
  }
}
