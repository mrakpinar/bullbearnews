import 'package:flutter/material.dart';

class ErrorStateWidget extends StatelessWidget {
  final bool isDark;
  final String? errorMessage;
  final VoidCallback onRetry; // VoidCallback kullan, parametre almaz

  const ErrorStateWidget({
    super.key,
    required this.isDark,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
                fontFamily: 'DMSerif',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF948979).withOpacity(0.8)
                    : const Color(0xFF393E46).withOpacity(0.8),
                fontFamily: 'DMSerif',
              ),
            ),
            const SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onRetry,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF393E46), Color(0xFF948979)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: const Color(0xFFDFD0B8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Try Again',
                        style: TextStyle(
                          color: const Color(0xFFDFD0B8),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          fontFamily: 'DMSerif',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
