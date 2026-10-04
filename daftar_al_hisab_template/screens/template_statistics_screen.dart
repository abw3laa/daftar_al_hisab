import 'package:flutter/material.dart';

import '../theme/template_spacing.dart';

class TemplateStatisticsScreen extends StatelessWidget {
  const TemplateStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('إجمالي الأجور', '—', Icons.payments_outlined),
      ('المستحقات', '—', Icons.account_balance_wallet_outlined),
      ('عدد العمال', '—', Icons.people_outline),
      ('عدد الورش', '—', Icons.home_work_outlined),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('الإحصائيات')),
      body: ListView.separated(
        padding: const EdgeInsets.all(TemplateSpacing.lg),
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(height: TemplateSpacing.sm),
        itemBuilder: (context, index) {
          final item = stats[index];
          return Card(
            child: ListTile(
              leading: Icon(item.$3),
              title: Text(item.$1),
              trailing: Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          );
        },
      ),
    );
  }
}
