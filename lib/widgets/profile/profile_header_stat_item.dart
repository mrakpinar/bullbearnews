import 'package:flutter/material.dart';

class ProfileHeaderStatItem extends StatelessWidget {
  final String label;
  final int count;
  final bool isDark;
  final bool isLoadingStats;
  final VoidCallback onTap;

  const ProfileHeaderStatItem(
      {super.key,
      required this.label,
      required this.count,
      required this.isDark,
      required this.onTap,
      required this.isLoadingStats});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Text(
              isLoadingStats ? '-' : count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
                fontFamily: 'DMSerif',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF948979),
                fontFamily: 'DMSerif',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
