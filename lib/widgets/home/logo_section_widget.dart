import 'package:flutter/material.dart';

class LogoSectionWidget extends StatelessWidget {
  final bool isDark;
  const LogoSectionWidget({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF393E46), Color(0xFF948979)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'BBN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFDFD0B8),
                  letterSpacing: 1.5,
                  fontFamily: 'DMSerif',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'BullBearNews',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color:
                    isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
                letterSpacing: -0.5,
                fontFamily: 'DMSerif',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Your crypto news destination 🚀',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
            fontWeight: FontWeight.w500,
            fontFamily: 'DMSerif',
          ),
        ),
      ],
    );
  }
}
