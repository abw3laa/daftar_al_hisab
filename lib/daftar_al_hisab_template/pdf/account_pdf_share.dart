import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../l10n/app_localizations.dart';
import '../../models/payment.dart';
import '../../providers/app_data.dart';
import '../../utils/formatters.dart';

class AccountPdfShare {
  static Future<void> shareStatement(AppData data, String workerId) async {
    final worker = data.workerById(workerId);
    if (worker == null) return;

    final font = await _font('assets/fonts/Amiri-Regular.ttf');
    final boldFont = await _font('assets/fonts/Amiri-Bold.ttf');
    final logo = await _logo();
    final transactions = data.transactionsForWorker(workerId);
    final balance = data.balanceForWorker(workerId);
    final totalJournal = data.totalJournalForWorker(workerId);
    final totalPayments = data.totalPaymentsForWorker(workerId);

    final isRtl = data.language == AppLanguage.ar;
    final title = data.language == AppLanguage.ar
        ? 'كشف حساب - ${worker.name}'
        : data.language == AppLanguage.tr
            ? 'Hesap Ekstresi - ${worker.name}'
            : 'Account Statement - ${worker.name}';

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: boldFont),
    );

    doc.addPage(
      pw.MultiPage(
        textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        header: (_) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Image(logo, width: 46, height: 46),
              pw.Text(
                data.t('app_name'),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        build: (_) => [
          pw.Header(level: 0, text: title),
          pw.Text('${data.t('name')}: ${worker.name}'),
          pw.Text('${data.t('profession')}: ${worker.profession.isEmpty ? '-' : worker.profession}'),
          if (worker.phone.isNotEmpty) pw.Text('${data.t('phone_optional')}: ${worker.phone}'),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFE8F5EF),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('${data.t('total_journal')}: ${Formatters.currency(totalJournal, data.currencySymbol)}'),
                pw.Text('${data.t('total_payments')}: ${Formatters.currency(totalPayments, data.currencySymbol)}'),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${data.t('balance_due_to_worker')}: ${Formatters.currency(balance, data.currencySymbol)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: [
              data.t('date'),
              data.language == AppLanguage.ar
                  ? 'البيان'
                  : data.language == AppLanguage.tr
                      ? 'Açıklama'
                      : 'Description',
              data.t('amount'),
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 10),
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
      bytes: await doc.save(),
      filename: 'kashf_hisab_${worker.name}.pdf',
    );
  }

  static Future<void> sharePaymentReceipt(
    AppData data,
    Payment payment,
  ) async {
    final worker = data.workerById(payment.workerId);
    if (worker == null) return;

    final font = await _font('assets/fonts/Amiri-Regular.ttf');
    final boldFont = await _font('assets/fonts/Amiri-Bold.ttf');
    final logo = await _logo();
    final balance = data.balanceForWorker(worker.id);
    final isRtl = data.language == AppLanguage.ar;

    final title = data.language == AppLanguage.ar
        ? 'إيصال دفعة - ${worker.name}'
        : data.language == AppLanguage.tr
            ? 'Ödeme Makbuzu - ${worker.name}'
            : 'Payment Receipt - ${worker.name}';

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: boldFont),
    );

    doc.addPage(
      pw.Page(
        textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(logo, width: 52, height: 52),
                pw.Text(
                  data.t('app_name'),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 17),
                ),
              ],
            ),
            pw.SizedBox(height: 22),
            pw.Header(level: 0, text: title),
            pw.SizedBox(height: 8),
            pw.Text('${data.t('name')}: ${worker.name}'),
            pw.Text('${data.t('profession')}: ${worker.profession.isEmpty ? '-' : worker.profession}'),
            if (worker.phone.isNotEmpty) pw.Text('${data.t('phone_optional')}: ${worker.phone}'),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF3F6FA),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${data.t('payment_type')}: ${payment.type.labelFor(data.language)}'),
                  pw.Text('${data.t('date')}: ${Formatters.date(payment.date)}'),
                  if (payment.notes.isNotEmpty) pw.Text('${data.t('notes_optional')}: ${payment.notes}'),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${data.t('amount')}: ${Formatters.currency(payment.amount, data.currencySymbol)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 17),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              '${data.language == AppLanguage.ar ? 'الرصيد بعد الدفعة' : data.language == AppLanguage.tr ? 'Ödeme sonrası bakiye' : 'Balance after payment'}: ${Formatters.currency(balance, data.currencySymbol)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'receipt_${worker.name}_${payment.id}.pdf',
    );
  }

  static Future<pw.Font> _font(String path) async =>
      pw.Font.ttf(await rootBundle.load(path));

  static Future<pw.MemoryImage> _logo() async {
    final bytes =
        (await rootBundle.load('assets/icon/app_icon.png')).buffer.asUint8List();
    return pw.MemoryImage(bytes);
  }
}
