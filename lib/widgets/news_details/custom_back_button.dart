import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final Color cardColor;
  final Color textColor;
  const CustomBackButton(
      {super.key, required this.cardColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_sharp,
            color: textColor,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
