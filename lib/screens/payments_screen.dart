import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/payment.dart';
import '../providers/app_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class PaymentsScreen extends StatelessWidget {
  final String workerId;
  const PaymentsScreen({super.key, required this.workerId});

  String _localized(AppData data, String ar, String en, String tr) {
    switch (data.language) {
      case AppLanguage.ar:
        return ar;
      case AppLanguage.en:
        return en;
      case AppLanguage.tr:
        return tr;
    }
  }

  String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);

  Future<void> _showPaymentEditor(BuildContext context, AppData data,
      {Payment? initial}) async {
    final amountController = TextEditingController(
        text: initial == null ? '' : _number(initial.amount));
    final notesController = TextEditingController(text: initial?.notes ?? '');
    PaymentType type = initial?.type ?? PaymentType.advance;
    DateTime date = initial?.date ?? DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(initial == null ? data.t('new_payment') : data.t('edit')),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<PaymentType>(
                initialValue: type,
                decoration: InputDecoration(labelText: data.t('payment_type')),
                items: PaymentType.values
                    .map((item) => DropdownMenuItem(
                        value: item, child: Text(item.labelFor(data.language))))
                    .toList(),
                onChanged: (value) => setState(() => type = value ?? type),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                autofocus: initial == null,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: data.t('amount'),
                  prefixIcon: const Icon(Icons.payments_outlined),
                  suffixText: data.currencySymbol,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => date = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: data.t('date'),
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(Formatters.date(date)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: data.t('notes_optional'),
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(data.t('cancel'))),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(
                    amountController.text.trim().replaceAll(',', '.'));
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(_localized(data,
                          'أدخل مبلغًا صحيحًا أكبر من صفر',
                          'Enter a valid amount greater than zero',
                          'Sıfırdan büyük geçerli bir tutar girin'))));
                  return;
                }
                if (initial == null) {
                  await data.addPayment(
                    workerId: workerId,
                    amount: amount,
                    type: type,
                    notes: notesController.text.trim(),
                    date: date,
                  );
                } else {
                  initial
                    ..amount = amount
                    ..type = type
                    ..notes = notesController.text.trim()
                    ..date = date;
                  await data.updatePayment(initial);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(data.t('save')),
            ),
          ],
        ),
      ),
    );
    amountController.dispose();
    notesController.dispose();
  }

  Future<bool> _confirmDelete(
      BuildContext context, AppData data, Payment payment) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data.t('delete')),
        content: Text(_localized(data, 'هل تريد حذف هذه الدفعة نهائيًا؟',
            'Delete this payment permanently?',
            'Bu ödeme kalıcı olarak silinsin mi?')),
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
    if (result == true) await data.deletePayment(payment.id);
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppData>(
      builder: (context, data, _) {
        final worker = data.workerById(workerId);
        final balance = data.balanceForWorker(workerId);
        final paymentsList = data.paymentsForWorker(workerId);
        final isPositive = balance >= 0;
        return Scaffold(
          appBar: AppBar(title: Text(worker?.name ?? data.t('payments'))),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showPaymentEditor(context, data),
            icon: const Icon(Icons.add_card_outlined),
            label: Text(data.t('new_payment')),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Card(
                margin: EdgeInsets.zero,
                color: isPositive
                    ? AppColors.secondaryContainer.withValues(alpha: 0.18)
                    : AppColors.errorContainer.withValues(alpha: 0.22),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    Text(
                      isPositive
                          ? data.t('balance_due_to_worker')
                          : _localized(data, 'الرصيد المدفوع زائدًا',
                              'Overpaid balance', 'Fazla ödenen bakiye'),
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Formatters.currency(balance.abs(), data.currencySymbol),
                      style: TextStyle(
                          fontSize: 29,
                          fontWeight: FontWeight.w800,
                          color: isPositive
                              ? AppColors.secondary
                              : AppColors.error),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
              Text(data.t('payments_log'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 10),
              if (paymentsList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 34),
                  child: Center(
                      child: Text(data.t('no_payments_yet'),
                          style: TextStyle(color: Colors.grey.shade600))),
                )
              else
                ...paymentsList.map((payment) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () => _showPaymentEditor(context, data,
                            initial: payment),
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.error.withValues(alpha: 0.12),
                          child: const Icon(Icons.payments_outlined,
                              color: AppColors.error),
                        ),
                        title: Text(payment.type.labelFor(data.language),
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            '${Formatters.date(payment.date)}${payment.notes.isNotEmpty ? ' · ${payment.notes}' : ''}'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(
                              Formatters.currency(
                                  payment.amount, data.currencySymbol),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await _showPaymentEditor(context, data,
                                    initial: payment);
                              } else {
                                await _confirmDelete(context, data, payment);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                  value: 'edit', child: Text(data.t('edit'))),
                              PopupMenuItem(
                                  value: 'delete',
                                  child: Text(data.t('delete'))),
                            ],
                          ),
                        ]),
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }
}
