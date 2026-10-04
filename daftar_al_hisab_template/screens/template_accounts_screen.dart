import 'package:flutter/material.dart';

import '../theme/template_spacing.dart';
import '../widgets/account_list_tile.dart';
import '../widgets/empty_state.dart';

class TemplateAccountsScreen extends StatelessWidget {
  const TemplateAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الحسابات'),
          bottom: const TabBar(tabs: [Tab(text: 'العمال'), Tab(text: 'الورش')]),
        ),
        body: const TabBarView(
          children: [
            _AccountsPlaceholder(label: 'حسابات العمال'),
            _AccountsPlaceholder(label: 'حسابات الورش'),
          ],
        ),
      ),
    );
  }
}

class _AccountsPlaceholder extends StatelessWidget {
  final String label;

  const _AccountsPlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(TemplateSpacing.lg),
      children: [
        Text(label, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: TemplateSpacing.md),
        AccountListTile(name: 'مثال حساب', subtitle: 'سيتم ربطه بالبيانات الحالية', balance: '—'),
        const SizedBox(height: TemplateSpacing.lg),
        const TemplateEmptyState(
          title: 'معاينة التصميم',
          message: 'هذه الشاشة معزولة عن منطق التطبيق حتى يتم ربطها بأمان.',
        ),
      ],
    );
  }
}
