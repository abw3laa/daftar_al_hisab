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

    // كشف الحساب يعرض الحركات من الأقدم إلى الأحدث حتى تكون القراءة
    // الزمنية طبيعية، مع تثبيت ترتيب الأعمدة بصرياً: التاريخ يميناً،
    // البيان في الوسط، والمبلغ يساراً.
    final orderedTransactions = [...transactions]
      ..sort((a, b) => a.date.compareTo(b.date));

    final dateLabel = data.t('date');
    final descriptionLabel = data.language == AppLanguage.ar
        ? 'البيان'
        : data.language == AppLanguage.tr
            ? 'Açıklama'
            : 'Description';
    final amountLabel = data.t('amount');

    pw.Widget rightText(
      String value, {
      double fontSize = 11,
      bool bold = false,
    }) {
      return pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          value,
          textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
    }

    pw.Widget tableCell(
      String value, {
      pw.Alignment alignment = pw.Alignment.centerRight,
      bool bold = false,
      PdfColor? color,
    }) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        alignment: alignment,
        child: pw.Text(
          value,
          textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          textAlign: alignment == pw.Alignment.centerLeft
              ? pw.TextAlign.left
              : alignment == pw.Alignment.center
                  ? pw.TextAlign.center
                  : pw.TextAlign.right,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      );
    }

    pw.TableRow tableRow({
      required String date,
      required String description,
      required String amount,
      PdfColor? amountColor,
      bool header = false,
    }) {
      // ترتيب العناصر هنا مقصود: المبلغ يساراً، البيان وسطاً، التاريخ يميناً.
      return pw.TableRow(
        children: [
          tableCell(
            amount,
            alignment: pw.Alignment.centerLeft,
            bold: header,
            color: amountColor,
          ),
          tableCell(
            description,
            alignment: pw.Alignment.centerRight,
            bold: header,
          ),
          tableCell(
            date,
            alignment: pw.Alignment.centerRight,
            bold: header,
          ),
        ],
      );
    }

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: boldFont),
    );

    doc.addPage(
      pw.MultiPage(
        textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        margin: const pw.EdgeInsets.fromLTRB(36, 30, 36, 30),
        header: (_) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  rightText(data.t('app_name'), fontSize: 15, bold: true),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    title,
                    textDirection:
                        isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(width: 10),
              pw.Image(logo, width: 48, height: 48),
            ],
          ),
        ),
        build: (_) => [
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 14),
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColor.fromInt(0xFF173F6B),
                  width: 1.5,
                ),
              ),
            ),
            child: rightText(
              '${data.t('name')}: ${worker.name}',
              fontSize: 13,
              bold: true,
            ),
          ),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(1.25),
              1: pw.FlexColumnWidth(2.9),
              2: pw.FlexColumnWidth(1.7),
            },
            border: pw.TableBorder.all(
              color: const PdfColor.fromInt(0xFF8DA4BA),
              width: 0.7,
            ),
            children: [
              tableRow(
                date: dateLabel,
                description: descriptionLabel,
                amount: amountLabel,
                header: true,
              ),
              ...orderedTransactions.map(
                (t) => tableRow(
                  date: Formatters.date(t.date),
                  description: t.title,
                  amount:
                      '${t.isCredit ? '+' : '-'}${Formatters.amount(t.amount)}',
                  amountColor: t.isCredit
                      ? const PdfColor.fromInt(0xFF147A38)
                      : const PdfColor.fromInt(0xFFC62828),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFEAF3FC),
              borderRadius: pw.BorderRadius.circular(7),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                rightText(
                  '${data.t('total_journal')}: ${Formatters.currency(totalJournal, data.currencySymbol)}',
                  fontSize: 12,
                ),
                pw.SizedBox(height: 4),
                rightText(
                  '${data.t('total_payments')}: ${Formatters.currency(totalPayments, data.currencySymbol)}',
                  fontSize: 12,
                ),
                pw.SizedBox(height: 7),
                pw.Container(
                  height: 1,
                  color: const PdfColor.fromInt(0xFF9DB9D3),
                ),
                pw.SizedBox(height: 7),
                rightText(
                  '${data.t('balance_due_to_worker')}: ${Formatters.currency(balance, data.currencySymbol)}',
                  fontSize: 15,
                  bold: true,
                ),
              ],
            ),
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
