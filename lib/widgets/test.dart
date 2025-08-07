import 'package:bullbearnews/services/push_notification_service.dart';
import 'package:flutter/material.dart';

class NotificationDebugWidget extends StatelessWidget {
  const NotificationDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            print('🔧 Force saving token...');
            await PushNotificationService.forceSaveToken();
          },
          child: Text('Force Save Token'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            print('🔍 Showing debug info...');
            await PushNotificationService.debugUserTokenInfo();
          },
          child: Text('Debug Token Info'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            print('🧪 Sending test notification...');
            await PushNotificationService.sendTestNotification();
          },
          child: Text('Send Test Notification'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            // Notification permission durumunu kontrol et
            final isEnabled =
                await PushNotificationService.isNotificationEnabled();
            print('📱 Notification enabled: $isEnabled');

            if (!isEnabled) {
              await PushNotificationService.requestPermission();
            }
          },
          child: Text('Check/Request Permission'),
        ),
      ],
    );
  }
}
