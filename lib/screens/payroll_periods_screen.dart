import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payroll_period.dart';
import '../providers/app_data.dart';
import '../utils/formatters.dart';

class PayrollPeriodsScreen extends StatefulWidget {
  const PayrollPeriodsScreen({super.key});
  @override State<PayrollPeriodsScreen> createState() => _PayrollPeriodsScreenState();
}

class _PayrollPeriodsScreenState extends State<PayrollPeriodsScreen> {
  int _year = DateTime.now().year;

  Future<void> _openPeriod(AppData data, PayrollPeriod period) async {
    final from = DateTime(period.year, period.month);
    final to = DateTime(period.year, period.month + 1);
    final accounting = await data.companyAccounting(from: from, to: to);
    if (!mounted) return;
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('كشف فترة ${period.label}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          _row('إجمالي الأجور', Formatters.currency(accounting.totalWages, data.currencySymbol)),
          _row('إجمالي المدفوع', Formatters.currency(accounting.totalPayments, data.currencySymbol)),
          _row('المتبقي', Formatters.currency(accounting.outstanding, data.currencySymbol)),
          const SizedBox(height: 18),
          if (!period.isClosed)
            FilledButton.icon(onPressed: () async {
              Navigator.pop(context);
              await data.closePayrollPeriod(period);
            }, icon: const Icon(Icons.lock_outline), label: const Text('إغلاق الفترة'))
          else
            OutlinedButton.icon(onPressed: () async {
              Navigator.pop(context);
              await data.reopenPayrollPeriod(period);
            }, icon: const Icon(Icons.lock_open_outlined), label: const Text('إعادة فتح الفترة')),
        ]),
      );
    });
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [Expanded(child: Text(label)), Text(value, style: const TextStyle(fontWeight: FontWeight.w800))]),
  );

  @override Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final periods = data.payrollPeriods.where((p) => p.year == _year).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('فترات الرواتب')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final now = DateTime.now();
          final p = await data.ensurePayrollPeriod(now.year, now.month);
          if (mounted) _openPeriod(data, p);
        },
        icon: const Icon(Icons.add), label: const Text('الفترة الحالية'),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
        Row(children: [
          IconButton(onPressed: () => setState(() => _year--), icon: const Icon(Icons.chevron_left)),
          Expanded(child: Center(child: Text('$_year', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)))),
          IconButton(onPressed: () => setState(() => _year++), icon: const Icon(Icons.chevron_right)),
        ]),
        const SizedBox(height: 8),
        ...periods.map((p) => Card(child: ListTile(
          leading: CircleAvatar(child: Text(p.month.toString())),
          title: Text('فترة ${p.label}', style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(p.isClosed ? 'مغلقة${p.closedAt == null ? '' : ' • ${p.closedAt!.day}/${p.closedAt!.month}'}' : 'مفتوحة'),
          trailing: Icon(p.isClosed ? Icons.lock_outline : Icons.lock_open_outlined),
          onTap: () => _openPeriod(data, p),
        ))),
        if (periods.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('لا توجد فترة رواتب محفوظة لهذه السنة.'))),
      ]),
    );
  }
}
