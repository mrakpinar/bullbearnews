import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PriceAlert {
  final String id;
  final String cryptoId;
  final String cryptoSymbol;
  final double targetPrice;
  final bool isAbove;
  final DateTime createdAt;

  PriceAlert({
    required this.id,
    required this.cryptoId,
    required this.cryptoSymbol,
    required this.targetPrice,
    required this.isAbove,
    required this.createdAt,
  });

  // Firestore'dan veri okurken kullanılacak
  factory PriceAlert.fromMap(Map<String, dynamic> map) {
    try {
      return PriceAlert(
        id: map['id'] ?? '', // null kontrolü eklendi
        cryptoId: map['cryptoId'] ?? '',
        cryptoSymbol: map['cryptoSymbol'] ?? '',
        targetPrice: (map['targetPrice'] as num?)?.toDouble() ?? 0.0,
        isAbove: map['isAbove'] as bool? ?? false,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error parsing PriceAlert: $e');
      debugPrint('Map data: $map');
      rethrow;
    }
  }
  factory PriceAlert.fromFirestore(Map<String, dynamic> data) {
    return PriceAlert(
      id: data['id'] as String,
      cryptoId: data['cryptoId'] as String,
      cryptoSymbol: data['cryptoSymbol'] as String,
      targetPrice: (data['targetPrice'] as num).toDouble(),
      isAbove: data['isAbove'] as bool,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Firestore'a veri yazarken kullanılacak
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cryptoId': cryptoId,
      'cryptoSymbol': cryptoSymbol,
      'targetPrice': targetPrice,
      'isAbove': isAbove,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
