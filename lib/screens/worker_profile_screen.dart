import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/worker.dart';
import '../providers/app_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/worker_avatar.dart';
import 'payments_screen.dart';

class WorkerProfileScreen extends StatelessWidget {
  final String workerId;
  const WorkerProfileScreen({super.key, required this.workerId});

  Future<void> _exportPdf(BuildContext context, AppData data) async {
    final worker = data.workerById(workerId);
    if (worker == null) return;
    final transactions = data.transactionsForWorker(workerId);
    final balance = data.balanceForWorker(workerId);

    // The default PDF fonts (Helvetica etc.) have no Arabic glyphs, which is
    // why Arabic text used to render as empty boxes/symbols. Loading a font
    // that actually covers Arabic script and setting it as the document's
    // base font fixes this for every piece of text in the PDF.
    final arabicFont =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Regular.ttf'));
    final arabicFontBold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Bold.ttf'));

    final isRtl = data.language == AppLanguage.ar;
    final statementTitle = data.language == AppLanguage.ar
        ? 'كشف حساب - ${worker.name}'
        : data.language == AppLanguage.tr
            ? 'Hesap Ekstresi - ${worker.name}'
            : 'Account Statement - ${worker.name}';
    final professionLabel = data.t('profession');
    final balanceLabel = data.t('balance_due_to_worker');
    final dateLabel = data.t('date');
    final detailsLabel = data.language == AppLanguage.ar
        ? 'البيان'
        : data.language == AppLanguage.tr
            ? 'Açıklama'
            : 'Description';
    final amountLabel = data.t('amount');

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold),
    );
    doc.addPage(
      pw.MultiPage(
        textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (pwContext) => [
          pw.Header(level: 0, text: statementTitle),
          pw.Text('$professionLabel: ${worker.profession}'),
          pw.SizedBox(height: 8),
          pw.Text(
            '$balanceLabel: ${Formatters.currency(balance, data.currencySymbol)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: [dateLabel, detailsLabel, amountLabel],
            data: transactions
                .map((t) => [
                      Formatters.date(t.date),
                      t.title,
                      '${t.isCredit ? '+' : '-'}${Formatters.amount(t.amount)}',
                    ])
                .toList(),
          ),
        ],
      ),
    );
    await Printing.sharePdf(
        bytes: await doc.save(), filename: 'kashf_hisab_${worker.name}.pdf');
  }

  Future<void> _showEditWorkerDialog(
      BuildContext context, AppData data, Worker worker) async {
    final nameController = TextEditingController(text: worker.name);
    final professionController = TextEditingController(text: worker.profession);
    final phoneController = TextEditingController(text: worker.phone);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data.t('edit')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: data.t('name')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: professionController,
              decoration: InputDecoration(labelText: data.t('profession')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: data.t('phone_optional')),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(data.t('cancel'))),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              worker.name = nameController.text.trim();
              worker.profession = professionController.text.trim();
              worker.phone = phoneController.text.trim();
              await data.updateWorker(worker);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(data.t('save')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppData>(
      builder: (context, data, _) {
        final worker = data.workerById(workerId);
        if (worker == null) {
          return Scaffold(
              body: Center(child: Text(data.language == AppLanguage.ar
                  ? 'لم يتم العثور على العامل'
                  : data.language == AppLanguage.tr
                      ? 'İşçi bulunamadı'
                      : 'Worker not found')));
        }
        final balance = data.balanceForWorker(workerId);
        final totalJournal = data.totalJournalForWorker(workerId);
        final totalPayments = data.totalPaymentsForWorker(workerId);
        final transactions = data.transactionsForWorker(workerId);
        final isOwed = balance >= 0;

        return Scaffold(
          appBar: AppBar(
            title: Text(worker.name),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    await _showEditWorkerDialog(context, data, worker);
                  } else if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(data.t('delete')),
                        content: Text(data.language == AppLanguage.ar
                            ? 'سيتم حذف العامل وكل سجلاته نهائياً. هل أنت متأكد؟'
                            : data.language == AppLanguage.tr
                                ? 'İşçi ve tüm kayıtları kalıcı olarak silinecek. Emin misiniz?'
                                : 'This will permanently delete the worker and all their records. Are you sure?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(data.t('cancel'))),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(data.t('delete'),
                                style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await data.deleteWorker(worker.id);
                      if (context.mounted) Navigator.pop(context);
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text(data.t('edit'))),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(data.t('delete'),
                        style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PaymentsScreen(workerId: workerId)),
            ),
            icon: const Icon(Icons.payments),
            label: Text(data.t('payments')),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    WorkerAvatar(initial: worker.initial, size: 72),
                    const SizedBox(height: 12),
                    Text(worker.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(worker.profession,
                        style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (worker.phone.isNotEmpty) ...[
                          IconButton.filledTonal(
                            onPressed: () =>
                                launchUrl(Uri.parse('tel:${worker.phone}')),
                            icon: const Icon(Icons.call),
                          ),
                          const SizedBox(width: 12),
                          IconButton.filledTonal(
                            onPressed: () =>
                                launchUrl(Uri.parse('sms:${worker.phone}')),
                            icon: const Icon(Icons.chat),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                    Text(data.t('balance_due_to_worker'),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                        label: data.t('total_journal'),
                        value: Formatters.currency(
                            totalJournal, data.currencySymbol),
                        color: AppColors.secondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStat(
                        label: data.t('total_payments'),
                        value: Formatters.currency(
                            totalPayments, data.currencySymbol),
                        color: AppColors.error),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(data.t('transactions_log'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
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
                ...transactions.map((t) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        t.isCredit ? Icons.work : Icons.payments,
                        color:
                            t.isCredit ? AppColors.secondary : AppColors.error,
                      ),
                      title: Text(t.title),
                      subtitle: Text(Formatters.dateLongArabic(t.date)),
                      trailing: Text(
                        '${t.isCredit ? '+' : '-'}${Formatters.amount(t.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: t.isCredit
                              ? AppColors.secondary
                              : AppColors.error,
                        ),
                      ),
                    )),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _exportPdf(context, data),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text(data.t('export_pdf')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(
                          text:
                              '${worker.name} - ${data.t('balance_due')}: ${Formatters.currency(balance, data.currencySymbol)}',
                        ),
                      ),
                      icon: const Icon(Icons.share),
                      label: Text(data.t('share')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: color, fontSize: 16)),
        ],
      ),
    );
  }
}
