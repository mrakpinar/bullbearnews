import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isVisible;
  final Animation<double> refreshAnimation;

  const LoadingOverlay({
    super.key,
    required this.isVisible,
    required this.refreshAnimation,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: refreshAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: refreshAnimation.value * 2 * 3.14159,
                    child: Icon(
                      Icons.refresh,
                      size: 32,
                      color: Theme.of(context).primaryColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Refreshing data...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we update the crypto prices',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
