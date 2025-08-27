import 'package:flutter/material.dart';

class ChatRoomBodyLoadingWidget extends StatelessWidget {
  const ChatRoomBodyLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading chat...',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontFamily: 'DMSerif',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
