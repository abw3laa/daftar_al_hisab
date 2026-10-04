import 'package:flutter/material.dart';

import '../theme/template_spacing.dart';
import '../widgets/balance_hero_card.dart';

class TemplateAccountDetailsScreen extends StatelessWidget {
  final String accountName;

  const TemplateAccountDetailsScreen({super.key, this.accountName = 'تفاصيل الحساب'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(accountName)),
      body: ListView(
        padding: const EdgeInsets.all(TemplateSpacing.lg),
        children: const [
          BalanceHeroCard(
            title: 'الرصيد',
            value: '—',
            subtitle: 'سيتم عرضه من البيانات الحالية',
          ),
          SizedBox(height: TemplateSpacing.lg),
          Card(
            child: ListTile(
              leading: Icon(Icons.receipt_long_outlined),
              title: Text('الحركات'),
              subtitle: Text('معاينة سجل الحركات المالية'),
            ),
          ),
        ],
      ),
    );
  }
}
