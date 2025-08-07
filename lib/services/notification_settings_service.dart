import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Notification settings model
  Map<String, dynamic> get defaultSettings => {
        'pushNotificationsEnabled': true,
        'breakingNewsEnabled': true,
        'trendingNewsEnabled': true,
        'categoryUpdatesEnabled': false,
        'weeklyDigestEnabled': true,
        'followNotificationsEnabled': true,
        'likeNotificationsEnabled': true,
        'shareNotificationsEnabled': true,
        'soundEnabled': true,
        'vibrationEnabled': true,
        'ledLightEnabled': false,
        'doNotDisturbEnabled': false,
        'morningDigestTime': {'hour': 8, 'minute': 0},
        'eveningDigestTime': {'hour': 18, 'minute': 0},
        'doNotDisturbStart': {'hour': 22, 'minute': 0},
        'doNotDisturbEnd': {'hour': 7, 'minute': 0},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  // Get current user's notification settings
  Future<Map<String, dynamic>> getUserSettings() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return defaultSettings;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        // Merge with default settings to ensure all keys exist
        final settings = Map<String, dynamic>.from(defaultSettings);
        settings.addAll(data);
        return settings;
      } else {
        // Create default settings for user
        await createDefaultSettings();
        return defaultSettings;
      }
    } catch (e) {
      print('Error getting user settings: $e');
      return defaultSettings;
    }
  }

  // Create default settings for user
  Future<void> createDefaultSettings() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('settings')
          .doc('notifications')
          .set(defaultSettings);

      print('✅ Default notification settings created');
    } catch (e) {
      print('❌ Error creating default settings: $e');
    }
  }

  // Update specific setting
  Future<void> updateSetting(String key, dynamic value) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('settings')
          .doc('notifications')
          .set({
        key: value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Setting updated: $key = $value');
    } catch (e) {
      print('❌ Error updating setting: $e');
    }
  }

  // Update multiple settings at once
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      settings['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('settings')
          .doc('notifications')
          .set(settings, SetOptions(merge: true));

      print('✅ Multiple settings updated');
    } catch (e) {
      print('❌ Error updating settings: $e');
    }
  }

  // Get settings stream for real-time updates
  Stream<Map<String, dynamic>> getSettingsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(defaultSettings);
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('settings')
        .doc('notifications')
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        final settings = Map<String, dynamic>.from(defaultSettings);
        settings.addAll(data);
        return settings;
      } else {
        createDefaultSettings();
        return defaultSettings;
      }
    });
  }

  // Check if notifications are enabled for specific type
  Future<bool> isNotificationEnabled(String type) async {
    final settings = await getUserSettings();

    // First check if push notifications are globally enabled
    if (!settings['pushNotificationsEnabled']) {
      return false;
    }

    // Check do not disturb
    if (settings['doNotDisturbEnabled'] && _isInDoNotDisturbPeriod(settings)) {
      return false;
    }

    // Check specific notification type
    switch (type) {
      case 'follow':
        return settings['followNotificationsEnabled'] ?? true;
      case 'like_portfolio':
        return settings['likeNotificationsEnabled'] ?? true;
      case 'share_portfolio':
        return settings['shareNotificationsEnabled'] ?? true;
      case 'breaking_news':
        return settings['breakingNewsEnabled'] ?? true;
      case 'trending_news':
        return settings['trendingNewsEnabled'] ?? true;
      case 'category_updates':
        return settings['categoryUpdatesEnabled'] ?? false;
      case 'weekly_digest':
        return settings['weeklyDigestEnabled'] ?? true;
      default:
        return true;
    }
  }

  // Check if current time is in do not disturb period
  bool _isInDoNotDisturbPeriod(Map<String, dynamic> settings) {
    if (!settings['doNotDisturbEnabled']) return false;

    final now = TimeOfDay.now();
    final startMap = settings['doNotDisturbStart'] as Map<String, dynamic>;
    final endMap = settings['doNotDisturbEnd'] as Map<String, dynamic>;

    final start = TimeOfDay(hour: startMap['hour'], minute: startMap['minute']);
    final end = TimeOfDay(hour: endMap['hour'], minute: endMap['minute']);

    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      // Same day period (e.g., 9 AM to 5 PM)
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } else {
      // Crosses midnight (e.g., 10 PM to 7 AM)
      return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
    }
  }

  // Convert TimeOfDay to Map for Firestore
  Map<String, int> timeOfDayToMap(TimeOfDay time) {
    return {'hour': time.hour, 'minute': time.minute};
  }

  // Convert Map to TimeOfDay
  TimeOfDay mapToTimeOfDay(Map<String, dynamic> map) {
    return TimeOfDay(hour: map['hour'] ?? 0, minute: map['minute'] ?? 0);
  }

  // Get notification preferences for FCM payload
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final settings = await getUserSettings();
    return {
      'sound': settings['soundEnabled'] ?? true,
      'vibration': settings['vibrationEnabled'] ?? true,
      'ledLight': settings['ledLightEnabled'] ?? false,
    };
  }

  // Reset settings to default
  Future<void> resetToDefaults() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('settings')
          .doc('notifications')
          .set(defaultSettings);

      print('✅ Settings reset to defaults');
    } catch (e) {
      print('❌ Error resetting settings: $e');
    }
  }

  // Export settings (for backup/import)
  Future<Map<String, dynamic>?> exportSettings() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        // Remove server timestamps for export
        data.remove('createdAt');
        data.remove('updatedAt');
        return data;
      }
      return null;
    } catch (e) {
      print('❌ Error exporting settings: $e');
      return null;
    }
  }

  // Import settings (from backup)
  Future<void> importSettings(Map<String, dynamic> settings) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      settings['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('settings')
          .doc('notifications')
          .set(settings, SetOptions(merge: true));

      print('✅ Settings imported successfully');
    } catch (e) {
      print('❌ Error importing settings: $e');
    }
  }
}
