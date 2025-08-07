import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chat",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.tertiary,
            fontFamily: 'DMSerif',
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_ios_new_sharp,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ),
      body: Center(
        child: Text('Chat Screen'),
      ),
    );
  }
}
