import 'package:flutter/material.dart';

import '../theme/template_spacing.dart';
import '../widgets/balance_hero_card.dart';

class TemplateDashboardScreen extends StatelessWidget {
  const TemplateDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الحسابات')),
      body: ListView(
        padding: const EdgeInsets.all(TemplateSpacing.lg),
        children: const [
          BalanceHeroCard(
            title: 'الرصيد الإجمالي',
            value: '—',
            subtitle: 'متصل بالبيانات الحالية عند الدمج',
          ),
          SizedBox(height: TemplateSpacing.lg),
          Card(
            child: ListTile(
              leading: Icon(Icons.people_alt_outlined),
              title: Text('الحسابات'),
              subtitle: Text('نظرة سريعة على العمال والورش'),
            ),
          ),
          SizedBox(height: TemplateSpacing.sm),
          Card(
            child: ListTile(
              leading: Icon(Icons.bar_chart_outlined),
              title: Text('الإحصائيات'),
              subtitle: Text('ملخص الحركة المالية'),
            ),
          ),
        ],
      ),
    );
  }
}
