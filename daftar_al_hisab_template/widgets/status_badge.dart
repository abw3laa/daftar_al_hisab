import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}
