import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_data.dart';
import '../../../daftar_al_hisab_template/theme/template_spacing.dart';
import '../../../daftar_al_hisab_template/widgets/balance_hero_card.dart';

class ConnectedTemplateDashboardScreen extends StatelessWidget {
  const ConnectedTemplateDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final currency = data.currencySymbol;

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الحسابات')),
      body: RefreshIndicator(
        onRefresh: data.reloadAll,
        child: ListView(
          padding: const EdgeInsets.all(TemplateSpacing.lg),
          children: [
            BalanceHeroCard(
              title: 'المستحقات الحالية',
              value: '${data.totalOwedToAllWorkers.toStringAsFixed(2)} $currency',
              subtitle: '${data.workers.length} عمال • ${data.workshops.length} ورش',
            ),
            const SizedBox(height: TemplateSpacing.lg),
            Card(
              child: ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('أجور هذا الشهر'),
                trailing: Text(
                  '${data.totalWagesThisMonth.toStringAsFixed(2)} $currency',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: TemplateSpacing.sm),
            Card(
              child: ListTile(
                leading: const Icon(Icons.people_alt_outlined),
                title: const Text('العمال'),
                trailing: Text(
                  '${data.workers.length}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: TemplateSpacing.sm),
            Card(
              child: ListTile(
                leading: const Icon(Icons.home_work_outlined),
                title: const Text('الورش'),
                trailing: Text(
                  '${data.workshops.length}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
