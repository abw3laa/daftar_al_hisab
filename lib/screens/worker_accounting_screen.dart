import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/worker.dart';
import '../providers/app_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class WorkerAccountingScreen extends StatefulWidget {
  final String workerId;
  const WorkerAccountingScreen({super.key, required this.workerId});
  @override
  State<WorkerAccountingScreen> createState() => _WorkerAccountingScreenState();
}

class _WorkerAccountingScreenState extends State<WorkerAccountingScreen> {
  int _period = 0;
  late Future<WorkerAccounting> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final now = DateTime.now();
    DateTime? from;
    DateTime? to;
    if (_period == 1) {
      from = DateTime(now.year, now.month);
      to = DateTime(now.year, now.month + 1);
    } else if (_period == 2) {
      from = DateTime(now.year, now.month, now.day);
      to = from.add(const Duration(days: 1));
    }
    _future = context.read<AppData>().accountingForWorker(widget.workerId, from: from, to: to);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final worker = data.workerById(widget.workerId);
    if (worker == null) return const Scaffold(body: Center(child: Text('العامل غير موجود')));
    return Scaffold(
      appBar: AppBar(title: Text('كشف حساب: ' + worker.name)),
      body: FutureBuilder<WorkerAccounting>(
        future: _future,
        builder: (context, snapshot) {
          final accounting = snapshot.data ?? const WorkerAccounting(earned: 0, paid: 0, balance: 0, transactions: []);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('كل الفترة')),
                  ButtonSegment(value: 1, label: Text('هذا الشهر')),
                  ButtonSegment(value: 2, label: Text('اليوم')),
                ],
                selected: {_period},
                onSelectionChanged: (v) => setState(() { _period = v.first; _load(); }),
              ),
              const SizedBox(height: 16),
              _WorkerIdentity(worker: worker),
              const SizedBox(height: 12),
              _BalanceHeader(accounting: accounting, currency: data.currencySymbol),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(child: Text('دفتر الحركات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                  if (snapshot.hasData) Text(
                    accounting.transactions.length.toString() + ' حركة',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (accounting.transactions.isEmpty)
                const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('لا توجد حركات في الفترة المحددة.')))
              else
                ...accounting.transactions.map((row) {
                  final credit = (row['credit'] as num? ?? 0).toDouble();
                  final debit = (row['debit'] as num? ?? 0).toDouble();
                  final amount = credit > 0 ? credit : debit;
                  final positive = credit > 0;
                  final date = DateTime.tryParse(row['date']?.toString() ?? '');
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (positive ? AppColors.secondary : AppColors.error).withValues(alpha: .12),
                        child: Icon(positive ? Icons.add : Icons.remove, color: positive ? AppColors.secondary : AppColors.error),
                      ),
                      title: Text(row['description']?.toString() ?? 'حركة'),
                      subtitle: Text(date == null ? '' : Formatters.dateLongArabic(date)),
                      trailing: Text(
                        (positive ? '+' : '-') + Formatters.currency(amount, data.currencySymbol),
                        style: TextStyle(fontWeight: FontWeight.w800, color: positive ? AppColors.secondary : AppColors.error),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  final WorkerAccounting accounting;
  final String currency;
  const _BalanceHeader({required this.accounting, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Row(children: [
            Expanded(child: _Item('المستحق', accounting.earned, AppColors.secondary, currency)),
            Expanded(child: _Item('المدفوع', accounting.paid, AppColors.error, currency)),
            Expanded(child: _Item('المتبقي', accounting.balance, AppColors.primary, currency)),
          ]),
        ]),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final String currency;
  const _Item(this.title, this.value, this.color, this.currency);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(title, style: const TextStyle(fontSize: 12)),
    const SizedBox(height: 6),
    Text(Formatters.currency(value, currency), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
  ]);
}


class _WorkerIdentity extends StatelessWidget {
  final Worker worker;
  const _WorkerIdentity({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          child: Text(worker.initial, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        title: Text(worker.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(worker.profession.isEmpty ? 'عامل' : worker.profession),
      ),
    );
  }
}
