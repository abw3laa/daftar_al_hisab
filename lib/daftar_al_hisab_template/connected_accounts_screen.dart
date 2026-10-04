import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/worker.dart';
import '../../models/workshop.dart';
import '../../providers/app_data.dart';
import '../../theme/app_theme.dart';
import '../../daftar_al_hisab_template/theme/template_spacing.dart';
import '../../daftar_al_hisab_template/widgets/account_list_tile.dart';
import '../../daftar_al_hisab_template/widgets/empty_state.dart';

class ConnectedTemplateAccountsScreen extends StatelessWidget {
  const ConnectedTemplateAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الحسابات'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'العمال'),
              Tab(text: 'الورش'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: data.reloadAll,
          child: TabBarView(
            children: [
              _WorkersTab(workers: data.workers, data: data),
              _WorkshopsTab(workshops: data.workshops, data: data),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkersTab extends StatelessWidget {
  final List<Worker> workers;
  final AppData data;

  const _WorkersTab({required this.workers, required this.data});

  @override
  Widget build(BuildContext context) {
    if (workers.isEmpty) {
      return const TemplateEmptyState(
        title: 'لا توجد حسابات عمال',
        message: 'ستظهر حسابات العمال المسجلة في التطبيق هنا.',
        icon: Icons.people_outline,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(TemplateSpacing.lg),
      itemCount: workers.length,
      separatorBuilder: (_, __) => const SizedBox(height: TemplateSpacing.sm),
      itemBuilder: (context, index) {
        final worker = workers[index];
        final balance = data.balanceForWorker(worker.id);
        final subtitle = worker.profession.trim().isEmpty
            ? 'عامل'
            : worker.profession.trim();

        return Card(
          child: AccountListTile(
            name: worker.name,
            subtitle: subtitle,
            balance: _money(balance, data.currencySymbol),
            onTap: () => _openWorker(context, worker),
          ),
        );
      },
    );
  }

  void _openWorker(BuildContext context, Worker worker) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConnectedTemplateWorkerDetailsScreen(
          workerId: worker.id,
        ),
      ),
    );
  }
}

class _WorkshopsTab extends StatelessWidget {
  final List<Workshop> workshops;
  final AppData data;

  const _WorkshopsTab({required this.workshops, required this.data});

  @override
  Widget build(BuildContext context) {
    if (workshops.isEmpty) {
      return const TemplateEmptyState(
        title: 'لا توجد ورش',
        message: 'ستظهر الورش المسجلة في التطبيق هنا.',
        icon: Icons.home_work_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(TemplateSpacing.lg),
      itemCount: workshops.length,
      separatorBuilder: (_, __) => const SizedBox(height: TemplateSpacing.sm),
      itemBuilder: (context, index) {
        final workshop = workshops[index];
        final cost = data.totalCostForWorkshop(workshop.id);

        return Card(
          child: AccountListTile(
            name: workshop.name,
            subtitle: workshop.location.trim().isEmpty
                ? workshop.status.label
                : '${workshop.status.label} • ${workshop.location.trim()}',
            balance: _money(cost, data.currencySymbol),
          ),
        );
      },
    );
  }
}

class ConnectedTemplateWorkerDetailsScreen extends StatelessWidget {
  final String workerId;

  const ConnectedTemplateWorkerDetailsScreen({
    super.key,
    required this.workerId,
  });

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final worker = data.workerById(workerId);

    if (worker == null) {
      return const Scaffold(
        body: TemplateEmptyState(
          title: 'العامل غير موجود',
          message: 'تعذر العثور على الحساب في البيانات الحالية.',
          icon: Icons.person_off_outlined,
        ),
      );
    }

    final balance = data.balanceForWorker(worker.id);

    return Scaffold(
      appBar: AppBar(title: Text(worker.name)),
      body: ListView(
        padding: const EdgeInsets.all(TemplateSpacing.lg),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  worker.initial,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              title: Text(
                worker.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                worker.profession.trim().isEmpty
                    ? 'عامل'
                    : worker.profession.trim(),
              ),
            ),
          ),
          const SizedBox(height: TemplateSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(TemplateSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الرصيد الحالي',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: TemplateSpacing.sm),
                  Text(
                    _money(balance, data.currencySymbol),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: balance > 0
                          ? AppColors.secondary
                          : balance < 0
                              ? AppColors.error
                              : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TemplateSpacing.md),
          const Card(
            child: ListTile(
              leading: Icon(Icons.receipt_long_outlined),
              title: Text('الحركات'),
              subtitle: Text(
                'سيتم عرض كشف الحركات التفصيلي في مرحلة ربط التفاصيل.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _money(double value, String currency) =>
    '${value.toStringAsFixed(2)} \$currency';
