import 'package:flutter/material.dart';

class IndicatorChipWidget extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const IndicatorChipWidget(
      {super.key,
      required this.label,
      required this.value,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontFamily: 'DMSerif',
            ),
          ),
        ],
      ),
    );
  }
}
