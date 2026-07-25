import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        build: (pwContext) => [
          pw.Header(level: 0, text: 'كشف حساب - ${worker.name}'),
          pw.Text('المهنة: ${worker.profession}'),
          pw.SizedBox(height: 8),
          pw.Text(
            'الرصيد المستحق: ${Formatters.currency(balance, data.currencySymbol)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['التاريخ', 'البيان', 'المبلغ'],
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
        bytes: await doc.save(), filename: 'كشف_حساب_${worker.name}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppData>(
      builder: (context, data, _) {
        final worker = data.workerById(workerId);
        if (worker == null) {
          return const Scaffold(body: Center(child: Text('لم يتم العثور على العامل')));
        }
        final balance = data.balanceForWorker(workerId);
        final totalJournal = data.totalJournalForWorker(workerId);
        final totalPayments = data.totalPaymentsForWorker(workerId);
        final transactions = data.transactionsForWorker(workerId);
        final isOwed = balance >= 0;

        return Scaffold(
          appBar: AppBar(title: Text(worker.name)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PaymentsScreen(workerId: workerId)),
            ),
            icon: const Icon(Icons.payments),
            label: const Text('المدفوعات'),
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
                            onPressed: () => launchUrl(
                                Uri.parse('sms:${worker.phone}')),
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
                      ? AppColors.secondaryContainer.withOpacity(0.3)
                      : AppColors.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text('الرصيد المستحق للعامل',
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
                        label: 'إجمالي اليوميات',
                        value: Formatters.currency(
                            totalJournal, data.currencySymbol),
                        color: AppColors.secondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStat(
                        label: 'إجمالي السلف',
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
                  const Text('سجل الحركات',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              if (transactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text('لا توجد حركات مسجلة بعد',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ),
                )
              else
                ...transactions.map((t) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        t.isCredit ? Icons.work : Icons.payments,
                        color: t.isCredit ? AppColors.secondary : AppColors.error,
                      ),
                      title: Text(t.title),
                      subtitle: Text(Formatters.dateLongArabic(t.date)),
                      trailing: Text(
                        '${t.isCredit ? '+' : '-'}${Formatters.amount(t.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: t.isCredit ? AppColors.secondary : AppColors.error,
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
                      label: const Text('تصدير PDF'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Share.share(
                        '${worker.name} - الرصيد المستحق: ${Formatters.currency(balance, data.currencySymbol)}',
                      ),
                      icon: const Icon(Icons.share),
                      label: const Text('مشاركة'),
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
  const _MiniStat({required this.label, required this.value, required this.color});

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
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 16)),
        ],
      ),
    );
  }
}
