import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isDark;
  const LoadingOverlay({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Searching users...',
            style: TextStyle(
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
