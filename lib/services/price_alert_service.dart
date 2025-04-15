import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/price_alert_model.dart';

class PriceAlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<PriceAlert>> getAlertsForCrypto(String cryptoId) {
    final userId = _auth.currentUser?.uid;
    debugPrint('Current user ID: $userId'); // Kullanıcı ID'sini kontrol et

    if (userId == null) {
      debugPrint('No user logged in, returning empty stream');
      return Stream.value([]);
    }

    final path = 'users/$userId/priceAlerts';
    debugPrint('Querying collection path: $path');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('priceAlerts')
        .where('cryptoId', isEqualTo: cryptoId)
        .snapshots()
        .map((snapshot) {
      debugPrint('Snapshot received, document count: ${snapshot.docs.length}');
      return snapshot.docs
          .map((doc) => PriceAlert.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> addAlert(PriceAlert alert) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('priceAlerts')
        .doc(alert.id)
        .set(alert.toMap());
  }

  Future<void> removeAlert(String alertId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('priceAlerts')
        .doc(alertId)
        .delete();
  }
}
