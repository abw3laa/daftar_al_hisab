import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/worker.dart';
import '../providers/app_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/worker_avatar.dart';
import 'add_journal_screen.dart';
import 'payments_screen.dart';

/// Shown as the first tab when the app is in "worker" usage mode: lets the
/// person log their own daily work and see their own balance, instead of
/// managing other workers as a contractor would.
class MyJournalTab extends StatelessWidget {
  const MyJournalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppData>(
      builder: (context, data, _) {
        if (data.myWorkerId == null || data.workerById(data.myWorkerId!) == null) {
          return _SetupPrompt(data: data);
        }
        return _MyJournalContent(workerId: data.myWorkerId!);
      },
    );
  }
}

class _SetupPrompt extends StatelessWidget {
  final AppData data;
  const _SetupPrompt({required this.data});

  Future<void> _pickOrCreateSelf(BuildContext context) async {
    final ar = data.language == AppLanguage.ar;
    final tr = data.language == AppLanguage.tr;
    final nameController = TextEditingController();

    final chosenId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ar
                  ? 'اختر اسمك من القائمة إن وُجد'
                  : tr
                      ? 'Varsa listeden adınızı seçin'
                      : 'Pick your name from the list if it exists',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (data.workers.isNotEmpty)
              SizedBox(
                height: 180,
                child: ListView(
                  children: data.workers
                      .map((w) => ListTile(
                            leading: WorkerAvatar(initial: w.initial, size: 36),
                            title: Text(w.name),
                            onTap: () => Navigator.pop(ctx, w.id),
                          ))
                      .toList(),
                ),
              ),
            const Divider(height: 32),
            Text(
              ar
                  ? 'أو أنشئ اسمك الآن'
                  : tr
                      ? 'Veya adınızı şimdi oluşturun'
                      : 'Or create your name now',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: data.t('name')),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final worker = await data.findOrCreateWorkerByName(name);
                if (ctx.mounted) Navigator.pop(ctx, worker.id);
              },
              child: Text(data.t('save')),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (chosenId != null) {
      await data.setMyWorkerId(chosenId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = data.language == AppLanguage.ar;
    final tr = data.language == AppLanguage.tr;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.badge, size: 64, color: AppColors.secondary),
              const SizedBox(height: 20),
              Text(
                ar
                    ? 'أنت في وضع "عامل" — حدّد من أنت لتبدأ بتسجيل عملك ومتابعة رصيدك'
                    : tr
                        ? '"İşçi" modundasınız — işinizi kaydetmeye başlamak için kim olduğunuzu belirleyin'
                        : 'You\'re in "worker" mode — set who you are to start logging your work and tracking your balance',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _pickOrCreateSelf(context),
                icon: const Icon(Icons.person_add),
                label: Text(
                  ar
                      ? 'تحديد هويتي'
                      : tr
                          ? 'Kimliğimi belirle'
                          : 'Set my identity',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyJournalContent extends StatelessWidget {
  final String workerId;
  const _MyJournalContent({required this.workerId});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppData>(
      builder: (context, data, _) {
        final worker = data.workerById(workerId) as Worker;
        final balance = data.balanceForWorker(workerId);
        final transactions = data.transactionsForWorker(workerId).take(10).toList();
        final isOwed = balance >= 0;

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: data.reloadAll,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    WorkerAvatar(initial: worker.initial, size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(worker.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                          Text(worker.profession,
                              style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isOwed
                        ? AppColors.secondaryContainer.withValues(alpha: 0.3)
                        : AppColors.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(data.t('balance_due'),
                          style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      Text(
                        Formatters.currency(balance.abs(), data.currencySymbol),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: isOwed ? AppColors.secondary : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  PaymentsScreen(workerId: workerId)),
                        ),
                        icon: const Icon(Icons.payments),
                        label: Text(data.t('payments')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(data.t('transactions_log'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                if (transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text(data.t('no_transactions_yet'),
                          style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  )
                else
                  ...transactions.map((t) => _MyTransactionTile(
                        transaction: t,
                        data: data,
                      )),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AddJournalScreen(lockedWorkerName: worker.name),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: Text(data.t('record_journal')),
          ),
        );
      },
    );
  }
}


class _MyTransactionTile extends StatelessWidget {
  final WorkerTransaction transaction;
  final AppData data;

  const _MyTransactionTile({required this.transaction, required this.data});

  Future<void> _delete(BuildContext context) async {
    final entry = transaction.journalEntry;
    if (entry == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data.t('delete')),
        content: Text(data.language == AppLanguage.ar
            ? 'سيتم حذف يومية العمل نهائيًا.'
            : data.language == AppLanguage.tr
                ? 'Çalışma kaydı kalıcı olarak silinecek.'
                : 'This work entry will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(data.t('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(data.t('delete'))),
        ],
      ),
    );
    if (confirmed == true) await data.deleteJournalEntry(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    final entry = transaction.journalEntry;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        transaction.isCredit ? Icons.work_outline : Icons.payments_outlined,
        color: transaction.isCredit ? AppColors.secondary : AppColors.error,
      ),
      title: Text(transaction.title),
      subtitle: Text(Formatters.dateLongArabic(transaction.date)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(
          '${transaction.isCredit ? '+' : '-'}${Formatters.amount(transaction.amount)}',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              color: transaction.isCredit
                  ? AppColors.secondary
                  : AppColors.error),
        ),
        if (entry != null)
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddJournalScreen(initialEntry: entry)),
                );
              } else {
                await _delete(context);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(data.t('edit'))),
              PopupMenuItem(value: 'delete', child: Text(data.t('delete'))),
            ],
          ),
      ]),
    );
  }
}
