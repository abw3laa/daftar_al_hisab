import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/payment.dart';
import '../providers/app_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class PaymentsScreen extends StatelessWidget {
  final String workerId;
  const PaymentsScreen({super.key, required this.workerId});

  Future<void> _showAddPaymentDialog(BuildContext context, AppData data) async {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    PaymentType type = PaymentType.advance;
    DateTime date = DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(data.t('new_payment')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<PaymentType>(
                initialValue: type,
                decoration: InputDecoration(labelText: data.t('payment_type')),
                items: PaymentType.values
                    .map((t) => DropdownMenuItem(
                        value: t, child: Text(t.labelFor(data.language))))
                    .toList(),
                onChanged: (v) => setState(() => type = v ?? type),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: data.t('amount'),
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
                  decoration: InputDecoration(labelText: data.t('date')),
                  child: Text(Formatters.date(date)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration:
                    InputDecoration(labelText: data.t('notes_optional')),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(data.t('cancel'))),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) return;
                await data.addPayment(
                  workerId: workerId,
                  amount: amount,
                  type: type,
                  notes: notesController.text.trim(),
                  date: date,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(data.t('save')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppData>(
      builder: (context, data, _) {
        final worker = data.workerById(workerId);
        final balance = data.balanceForWorker(workerId);
        final paymentsList = data.paymentsForWorker(workerId);

        return Scaffold(
          appBar: AppBar(title: Text(worker?.name ?? data.t('payments'))),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddPaymentDialog(context, data),
            icon: const Icon(Icons.add_circle),
            label: Text(data.t('new_payment')),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Text(data.t('balance_due'),
                        style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Text(
                      Formatters.currency(balance.abs(), data.currencySymbol),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: balance >= 0
                            ? AppColors.secondary
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(data.t('payments_log'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              if (paymentsList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(data.t('no_payments_yet'),
                        style: TextStyle(color: Colors.grey.shade600)),
                  ),
                )
              else
                ...paymentsList.map((p) => Dismissible(
                      key: ValueKey(p.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: AppColors.error,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => data.deletePayment(p.id),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          p.type == PaymentType.advance
                              ? Icons.money
                              : Icons.payments,
                          color: AppColors.error,
                        ),
                        title: Text(p.type.labelFor(data.language)),
                        subtitle: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 12),
                            const SizedBox(width: 4),
                            Text(Formatters.date(p.date)),
                          ],
                        ),
                        trailing: Text(
                          Formatters.currency(p.amount, data.currencySymbol),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }
}
