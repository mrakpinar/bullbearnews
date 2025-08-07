import 'dart:typed_data';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firebase Project ID
  static const String _projectId = 'bullbearnews-4eff4';

  // Service Account JSON
  static const String _serviceAccountJson = '''
{
  "type": "service_account",
  "project_id": "bullbearnews-4eff4",
  "private_key_id": "81fd532e378dabf47e761cdecbf52c4b1fc324f6",
  "private_key": "-----BEGIN PRIVATE KEY-----\\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDHNKVRMdE+j/A0\\ny18eBksVsv+omFPR9EsTr8Thx8NOD9oTbbvOpLoBzsU80x6Gdtb6C86G1MHH36aZ\\n79oZAooqw4A/4IqGT2jzzlbDjP6bcnFstilfzSpGr2pO9dAShYeHRj39h/Fo7+ZT\\n9EaxllYNotwYcgx1Eums0iZsNdFeWa/7wWZXpOntXRAmkI9AfwWz6n0tsQfRlSf6\\nOrzCX8Mm4drfKl4EqLId+qiLt2ZMnqjSXLQxsh3Xfa+foibQs41+Qq5wYFryrrcY\\nIjWSIJtnculXFzRiYZv5fO7/hVht8hnyOBJlB3YxxXlq9h52Fm8s/DeE4S3U6Mra\\n4KB/9SXVAgMBAAECggEAWqkMlgPgsaLrlPN70hvWH0WMUiwldbfDVW3Y4lK6gbP4\\nMYBvCXBx0THMFU8WJOdAFqO59iYtHSyd05BUB67et/Cq1Sd5k//fCZq+ZRgtpgxz\\nL6FF+jpTA8GA1ffMnylTUY731oOArJwGDO5vIBKGDoWwupVpMv0NCWDJKNVjeJb1\\nRjbilcVcesd1smLdYk/dz1/Eu73o5dY55nitFYGojF4qq5HBgGG0Ds2U30Jtrmmd\\noblSD/b23hZ/0Zzy4tsRkMTSl2bdgozS7ymuViltMFDv3WeBrC8jtht+ENQ/Q9rw\\naDoBJer+vdxmYgPur1p0xSyKTuvXNzdfFLk11z5DfwKBgQD5xv+n2pyeg/0eDTyE\\ngmrJQ2iA7BbJV7e0QL/CtDdZQFcoadg9mSUikCe/tjqHmrdRPCGgcpxGmW7VqMyq\\nSnisFTxib9BGto3X4zAG6L08BuyxZeNphh1K2fh71NHGT0PGaqYx3tXKrYEtlMgO\\nzxDWfb2slTvjtWWXH2hDjCjYMwKBgQDMKx3kgV4E5rvgzAeOiWudLi2JXmoRDp/B\\nb/ZX+RApef7R8WE00PRMcZWubrZzA6vNOxAXVgD20rDC6v7nT6E7rcMlGRN+YZcY\\nCOfjEqJ1bLPTrnvTCLg9SSbRFmZouBDENJTzaWSDnrWvDEV6Yi5ROLt1ncjHaZvK\\nLH8vnhMh1wKBgEISWd5U/ckQsQwaBEApH4ZNxn8T9JMeGQIdfpxKf7mkQ2n1VbY1\\npJUX/OvBkIn+ay+Z8Gs45g3m2GK8XCdPu8wJcge3/Cg4ch0Bg9rQBf6y9jmW8ikf\\nyO/b6NcY3MTQguUhoQTgJT2P1/Puv1zreVDDwkC82TLK8Sygqjvz/3nxAoGAZ5GT\\nt1+8ruXQ9qbpSnABbBmJtf5z9bUia0D9iQDqJvAgyKUWt3EsDD8uO+8jlFKPayuD\\n7SKOmKamTiphJjupwZlSvdXropekyudxoinIyaJb0ozXeWUZ+NTL4RLo3kRJFQ7L\\nZHLZLz9qUKL796oobsFFrtNcj3POOI+78Q7SC78CgYA0X9AK0GZHUi4IdqT7rJSI\\nqrpS5iNX5SpfYiDhYLxtTT0QZB1aMeCfVBO6T9iFlIbnF6mbtvmPUHUxT2cQSxO7\\niB1LoroCRGPDdFlYeuVTCfhch3GGjdjciiqY5vHRZo6TUZmVzYmvhDOLGW+QUShr\\npPPKhvfi7iNVuy+3iHL9hQ==\\n-----END PRIVATE KEY-----\\n",
  "client_email": "firebase-adminsdk-fbsvc@bullbearnews-4eff4.iam.gserviceaccount.com",
  "client_id": "114287783538347840783",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40bullbearnews-4eff4.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
''';

  // Initialize notifications
  static Future<void> initialize() async {
    print('🚀 Initializing push notifications...');

    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('📱 Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('❌ Notification permission not granted');
      return;
    }

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when user taps on notification while app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Save FCM token to user document - EN ÖNEMLİ KISIM!
    await _saveFCMToken();

    print('✅ Push notifications initialized successfully');
  }

  // FCM Token'ı kaydet ve debug bilgileri göster
  static Future<void> _saveFCMToken() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ No authenticated user, cannot save FCM token');
      return;
    }

    print('👤 Current user ID: ${currentUser.uid}');

    try {
      // Token'ı al
      final token = await _messaging.getToken();
      if (token != null) {
        print('🔑 FCM Token obtained: ${token.substring(0, 50)}...');
        print('📏 Full token length: ${token.length}');

        // Firestore'a kaydet
        await _firestore.collection('users').doc(currentUser.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'platform': 'android', // veya ios
          'appVersion': '1.0.0',
        }, SetOptions(merge: true));

        print('💾 FCM Token saved to Firestore successfully');

        // Kaydedilen token'ı doğrula
        await _verifyStoredToken(currentUser.uid);
      } else {
        print('❌ Failed to get FCM token');
      }

      // Token refresh listener
      _messaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM Token refreshed: ${newToken.substring(0, 50)}...');
        _firestore.collection('users').doc(currentUser.uid).set({
          'fcmToken': newToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      print('💥 Error saving FCM token: $e');
    }
  }

  // Kaydedilen token'ı doğrula
  static Future<void> _verifyStoredToken(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final storedToken = data['fcmToken'];
        final lastUpdate = data['lastTokenUpdate'];

        print('✅ Verification - Token stored: ${storedToken != null}');
        print('📅 Last update: $lastUpdate');

        if (storedToken != null) {
          print('🔑 Stored token preview: ${storedToken.substring(0, 50)}...');
        }
      } else {
        print('❌ User document does not exist in Firestore');
      }
    } catch (e) {
      print('💥 Error verifying stored token: $e');
    }
  }

  // Token'ı manuel olarak kaydet (debug için)
  static Future<void> forceSaveToken() async {
    print('🔧 Force saving FCM token...');
    await _saveFCMToken();
  }

  // Kullanıcının token bilgilerini göster (debug için)
  static Future<void> debugUserTokenInfo() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ No authenticated user');
      return;
    }

    print('🔍 DEBUG: User token information');
    print('👤 User ID: ${currentUser.uid}');
    print('📧 Email: ${currentUser.email}');

    try {
      // Mevcut token'ı al
      final currentToken = await _messaging.getToken();
      print('📱 Current FCM Token: ${currentToken?.substring(0, 142)}...');

      // Firestore'dan kontrol et
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        print('💾 Stored in Firestore:');
        print('   - FCM Token exists: ${data.containsKey('fcmToken')}');
        print(
            '   - Token preview: ${data['fcmToken']?.toString().substring(0, 50)}...');
        print('   - Last update: ${data['lastTokenUpdate']}');
      } else {
        print('❌ User document not found in Firestore');
      }
    } catch (e) {
      print('💥 Error in debug: $e');
    }
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print(
          '🔔 Message also contained a notification: ${message.notification}');
      await _showNotification(message);
    }
  }

  // Handle when notification is tapped
  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('👆 A new onMessageOpenedApp event was published!');
    _handleNotificationNavigation(message.data);
  }

  // Handle local notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('👆 Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      _handleNotificationNavigation(data);
    }
  }

  // Show local notification
  static Future<void> _showNotification(RemoteMessage message) async {
    print('🔔 Showing local notification for message: ${message.messageId}');

    // Notification icon
    String notificationIcon = '@drawable/ic_notification';

    // Android notification details
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      // Küçük notification icon (status bar'da görünen)
      icon: notificationIcon,
      // Large icon için URL varsa bitmap olarak yükle
      largeIcon: message.data.containsKey('senderProfileImage') &&
              message.data['senderProfileImage']!.isNotEmpty
          ? const DrawableResourceAndroidBitmap('@drawable/ic_launcher')
          : null,
      // Renk (Android 5.0+)
      color: const Color(0xFFFF6B35),
      // Ledler için renk
      ledColor: const Color(0xFFFF6B35),
      ledOnMs: 1000,
      ledOffMs: 500,
      // Notification stil
      styleInformation: BigTextStyleInformation(
        message.notification?.body ?? '',
        htmlFormatBigText: true,
        contentTitle: message.notification?.title,
        htmlFormatContentTitle: true,
      ),
      // Ses ve titreşim
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
      // Otomatik iptal
      autoCancel: true,
      // Ongoing (kullanıcı kaydırana kadar kalır)
      ongoing: false,
      // Notification kategorisi
      category: AndroidNotificationCategory.social,
      // Visibility
      visibility: NotificationVisibility.public,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default.wav',
      badgeNumber: 1,
      attachments: [], // iOS için media attachments
      categoryIdentifier: 'general',
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    try {
      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'New Notification',
        message.notification?.body ?? 'You have a new notification',
        platformChannelSpecifics,
        payload: json.encode(message.data),
      );
      print('✅ Local notification shown successfully');
    } catch (e) {
      print('💥 Error showing local notification: $e');
    }
  }

  // Handle notification navigation
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    print('🧭 Navigate to: ${data['type']}, senderId: ${data['senderId']}');
  }

  // Get access token for FCM v1 API
  static Future<String> _getAccessToken() async {
    try {
      final serviceAccount = ServiceAccountCredentials.fromJson(
        json.decode(_serviceAccountJson),
      );

      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final authClient = await clientViaServiceAccount(serviceAccount, scopes);
      final accessToken = authClient.credentials.accessToken.data;

      authClient.close();
      return accessToken;
    } catch (e) {
      print('💥 Error getting access token: $e');
      rethrow;
    }
  }

  // Send push notification using FCM v1 API
  static Future<void> sendPushNotification({
    required String targetUserId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('📤 Sending push notification to user: $targetUserId');

      // Get target user's FCM token
      final userDoc =
          await _firestore.collection('users').doc(targetUserId).get();

      if (!userDoc.exists) {
        print('❌ User document not found for ID: $targetUserId');
        return;
      }

      final userData = userDoc.data();
      if (userData == null) {
        print('❌ User data is null');
        return;
      }

      final fcmToken = userData['fcmToken'];
      if (fcmToken == null || fcmToken.isEmpty) {
        print('❌ FCM token not found for user: $targetUserId');
        print(
            '🔍 Available fields in user document: ${userData.keys.toList()}');

        // Token yoksa yeniden kaydetmeyi dene
        print('🔄 Attempting to refresh FCM token...');
        await _saveFCMToken();

        return;
      }

      print('✅ Found FCM token for user: ${fcmToken.substring(0, 50)}...');

      // Get access token
      final accessToken = await _getAccessToken();
      print('🔑 Access token obtained successfully');

      // Prepare notification payload for FCM v1 API
      final message = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data.map((key, value) => MapEntry(key, value.toString())),
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'high_importance_channel',
              'sound': 'default',
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
                'category': 'FLUTTER_NOTIFICATION_CLICK',
              },
            },
          },
        },
      };

      print('📨 Sending FCM v1 message...');

      // Send notification via FCM v1 API
      final response = await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(message),
      );

      print('📊 FCM Response Status: ${response.statusCode}');
      print('📄 FCM Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Push notification sent successfully');
      } else {
        print(
            '❌ Failed to send push notification: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('💥 Error sending push notification: $e');
    }
  }

  // Send notification to multiple users
  static Future<void> sendMulticastNotification({
    required List<String> userIds,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    print('📤 Sending multicast notification to ${userIds.length} users');

    for (String userId in userIds) {
      await sendPushNotification(
        targetUserId: userId,
        title: title,
        body: body,
        data: data,
      );
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  // Get notification permission status
  static Future<bool> isNotificationEnabled() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // Request notification permission
  static Future<void> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('📱 Permission request result: ${settings.authorizationStatus}');
  }

  // Test notification with debug info
  static Future<void> sendTestNotification() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ No authenticated user for test notification');
      return;
    }

    print('🧪 Sending test notification...');

    // Önce debug bilgilerini göster
    await debugUserTokenInfo();

    // Eğer token yoksa kaydetmeyi dene
    await forceSaveToken();

    // Biraz bekle
    await Future.delayed(const Duration(seconds: 2));

    // Test notification gönder
    await sendPushNotification(
      targetUserId: currentUser.uid,
      title: 'Test Notification 🧪',
      body: 'This is a test notification to verify FCM v1 API setup',
      data: {
        'type': 'test',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }
}
