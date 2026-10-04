import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/worker.dart';
import '../../models/workshop.dart';
import '../../providers/app_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'package:daftar_al_hisab/daftar_al_hisab_template/pdf/account_pdf_share.dart';
import 'package:daftar_al_hisab/daftar_al_hisab_template/theme/template_spacing.dart';
import '../../screens/worker_profile_screen.dart';
import 'package:daftar_al_hisab/daftar_al_hisab_template/widgets/account_list_tile.dart';
import 'package:daftar_al_hisab/daftar_al_hisab_template/widgets/empty_state.dart';

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
            balance: Formatters.currency(balance, data.currencySymbol),
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
            balance: Formatters.currency(cost, data.currencySymbol),
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
    final transactions = data.transactionsForWorker(worker.id);
    final totalJournal = data.totalJournalForWorker(worker.id);
    final totalPayments = data.totalPaymentsForWorker(worker.id);
    final profession = worker.profession.trim().isEmpty
        ? 'عامل'
        : worker.profession.trim();
    final balanceColor = balance > 0
        ? AppColors.secondary
        : balance < 0
            ? AppColors.error
            : Theme.of(context).colorScheme.onSurfaceVariant;
    final balanceStatus = balance > 0
        ? 'مستحق للعامل'
        : balance < 0
            ? 'رصيد سالب'
            : 'الرصيد متوازن';

    return Scaffold(
      appBar: AppBar(title: Text(worker.name)),
      body: ListView(
        padding: const EdgeInsets.all(TemplateSpacing.lg),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(TemplateSpacing.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    child: Text(
                      worker.initial,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: TemplateSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: TemplateSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TemplateSpacing.sm,
                            vertical: TemplateSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            profession,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TemplateSpacing.md),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(TemplateSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'الرصيد الحالي',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TemplateSpacing.sm,
                          vertical: TemplateSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: balanceColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          balanceStatus,
                          style: TextStyle(
                            color: balanceColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TemplateSpacing.sm),
                  Text(
                    Formatters.currency(balance, data.currencySymbol),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: balanceColor,
                    ),
                  ),
                  const SizedBox(height: TemplateSpacing.xs),
                  Text(
                    'محسوب من إجمالي اليوميات والمدفوعات المسجلة.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TemplateSpacing.md),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text(
                    'كشف الحساب',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'مشاركة كشف PDF يتضمن المعلومات والحركات والرصيد.',
                  ),
                  trailing: const Icon(Icons.picture_as_pdf_outlined),
                  onTap: () => AccountPdfShare.shareStatement(data, worker.id),
                ),
                const Divider(height: 1, indent: 68),
                ListTile(
                  leading: const Icon(Icons.open_in_new_outlined),
                  title: const Text(
                    'فتح الحساب الكامل',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'عرض وإدارة اليوميات والمدفوعات من الشاشة الأصلية.',
                  ),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WorkerProfileScreen(workerId: worker.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TemplateSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _DetailStat(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'إجمالي المستحق',
                  value: Formatters.currency(totalJournal, data.currencySymbol),
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: TemplateSpacing.sm),
              Expanded(
                child: _DetailStat(
                  icon: Icons.payments_outlined,
                  label: 'إجمالي المدفوع',
                  value: Formatters.currency(totalPayments, data.currencySymbol),
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: TemplateSpacing.lg),
          Text(
            'سجل الحركات',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: TemplateSpacing.xs),
          Text(
            'اليوميات والمدفوعات مرتبة من الأحدث إلى الأقدم.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: TemplateSpacing.sm),
          if (transactions.isEmpty)
            const Card(
              child: TemplateEmptyState(
                title: 'لا توجد حركات بعد',
                message: 'ستظهر اليوميات والمدفوعات المسجلة لهذا العامل هنا.',
                icon: Icons.receipt_long_outlined,
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < transactions.length; i++) ...[
                    _TransactionRow(
                      transaction: transactions[i],
                      currency: data.currencySymbol,
                    ),
                    if (i < transactions.length - 1)
                      const Divider(height: 1, indent: 68),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(TemplateSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              foregroundColor: color,
              child: Icon(icon, size: 19),
            ),
            const SizedBox(height: TemplateSpacing.sm),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: TemplateSpacing.xs),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final WorkerTransaction transaction;
  final String currency;

  const _TransactionRow({
    required this.transaction,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final color = transaction.isCredit ? AppColors.secondary : AppColors.error;
    final icon = transaction.isCredit
        ? Icons.work_history_outlined
        : Icons.payments_outlined;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: TemplateSpacing.md,
        vertical: TemplateSpacing.xs,
      ),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        child: Icon(icon, size: 20),
      ),
      title: Text(
        transaction.title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${Formatters.dateLongArabic(transaction.date)}'
        '${transaction.subtitle.isNotEmpty ? ' • ${transaction.subtitle}' : ''}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${transaction.isCredit ? '+' : '-'}${Formatters.amount(transaction.amount)} $currency',
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}
