import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WorkerAvatar extends StatelessWidget {
  final String initial;
  final double size;

  const WorkerAvatar({super.key, required this.initial, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
