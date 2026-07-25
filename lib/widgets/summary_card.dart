import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final bool positive;
  final IconData? icon;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.positive = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.secondary : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (icon != null) Icon(icon, color: color, size: 20),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
