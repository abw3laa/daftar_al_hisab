import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'worker_profile_screen.dart';
import 'worker_accounting_screen.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});
  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  int _period = 0;
  String _query = '';
  late Future<CompanyAccounting> _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final data = context.read<AppData>();
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
    _future = data.companyAccounting(from: from, to: to);
  }

  void _setPeriod(int value) => setState(() {
    _period = value;
    _refresh();
  });

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحاسبة'),
        actions: [IconButton(onPressed: () => setState(_refresh), icon: const Icon(Icons.refresh))],
      ),
      body: FutureBuilder<CompanyAccounting>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final accounting = snapshot.data ?? const CompanyAccounting(totalWages: 0, totalPayments: 0, outstanding: 0);
          return RefreshIndicator(
            onRefresh: () async => setState(_refresh),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _periodSelector(),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: const InputDecoration(
                    hintText: 'ابحث عن عامل بالاسم أو المهنة',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 620;
                    final cards = [
                      _MetricCard(title: 'إجمالي المستحق', value: accounting.totalWages, icon: Icons.account_balance_wallet_outlined),
                      _MetricCard(title: 'إجمالي المدفوع', value: accounting.totalPayments, icon: Icons.payments_outlined),
                      _MetricCard(title: 'الرصيد المستحق', value: accounting.outstanding, icon: Icons.receipt_long_outlined, emphasize: true),
                    ];
                    if (wide) {
                      return Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsetsDirectional.only(end: 10), child: c))).toList());
                    }
                    return Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c)).toList());
                  },
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.surfaceContainer,
                          child: Icon(Icons.table_chart_outlined, color: AppColors.primary),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('دفتر الحركات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              SizedBox(height: 4),
                              Text('كل يومية ودفعة تُحفظ كحركة محاسبية قابلة للمراجعة.'),
                            ],
                          ),
                        ),
                        Text(data.journalEntries.length.toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(child: Text('أرصدة العمال', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
                    Text(
                      data.workers.length.toString() + ' عامل',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...data.workers.where((worker) {
                  if (_query.isEmpty) return true;
                  final q = _query.toLowerCase();
                  return worker.name.toLowerCase().contains(q) ||
                      worker.profession.toLowerCase().contains(q);
                }).map((worker) {
                  final balance = data.balanceForWorker(worker.id);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(worker.initial)),
                      title: Text(worker.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(worker.profession.isEmpty ? 'عامل' : worker.profession),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(Formatters.currency(balance, data.currencySymbol),
                              style: TextStyle(fontWeight: FontWeight.w800, color: balance >= 0 ? AppColors.secondary : AppColors.error)),
                          Text(
                            balance > 0 ? 'مستحق للعامل' : balance < 0 ? 'مدفوع زائد' : 'مسدد',
                            style: TextStyle(
                              fontSize: 10,
                              color: balance > 0 ? AppColors.secondary : balance < 0 ? AppColors.error : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerAccountingScreen(workerId: worker.id)),),
                    ),
                  );
                }),
                if (data.workers.isEmpty)
                  const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('أضف العمال لتظهر حساباتهم هنا.')))
                else if (data.workers.where((worker) {
                  if (_query.isEmpty) return true;
                  final q = _query.toLowerCase();
                  return worker.name.toLowerCase().contains(q) || worker.profession.toLowerCase().contains(q);
                }).isEmpty)
                  const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('لا يوجد عامل مطابق للبحث.'))),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _periodSelector() => SegmentedButton<int>(
    segments: const [
      ButtonSegment(value: 0, label: Text('كل الفترة')),
      ButtonSegment(value: 1, label: Text('هذا الشهر')),
      ButtonSegment(value: 2, label: Text('اليوم')),
    ],
    selected: {_period},
    onSelectionChanged: (v) => _setPeriod(v.first),
  );
}

class _MetricCard extends StatelessWidget {
  final String title;
  final double value;
  final IconData icon;
  final bool emphasize;
  const _MetricCard({required this.title, required this.value, required this.icon, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    final data = context.read<AppData>();
    return Card(
      color: emphasize ? AppColors.primary : null,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: emphasize ? Colors.white : AppColors.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: emphasize ? Colors.white70 : Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(Formatters.currency(value, data.currencySymbol),
                      style: TextStyle(color: emphasize ? Colors.white : null, fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
