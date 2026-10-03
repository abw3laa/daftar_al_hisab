import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class BatchJournalScreen extends StatefulWidget {
  final DateTime initialDate;
  const BatchJournalScreen({super.key, required this.initialDate});
  @override
  State<BatchJournalScreen> createState() => _BatchJournalScreenState();
}

class _BatchRow {
  final String workerId;
  bool present = true;
  double fraction = 1;
  final wage = TextEditingController();
  final overtimeHours = TextEditingController(text: '0');
  final overtimeRate = TextEditingController(text: '0');
  final deduction = TextEditingController(text: '0');
  _BatchRow(this.workerId, double defaultWage) {
    wage.text = defaultWage == defaultWage.roundToDouble() ? defaultWage.toInt().toString() : defaultWage.toStringAsFixed(2);
  }
  double n(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;
  double get total => present ? ((n(wage) * fraction) + (n(overtimeHours) * n(overtimeRate)) - n(deduction)).clamp(0, double.infinity).toDouble() : 0;
  void dispose() { wage.dispose(); overtimeHours.dispose(); overtimeRate.dispose(); deduction.dispose(); }
}

class _BatchJournalScreenState extends State<BatchJournalScreen> {
  late DateTime _date;
  String? _workshopId;
  final Map<String, _BatchRow> _rows = {};
  bool _saving = false;

  @override
  void initState() { super.initState(); _date = widget.initialDate; }

  @override
  void dispose() { for (final row in _rows.values) row.dispose(); super.dispose(); }

  Future<void> _pickDate() async {
    final value = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (value != null) setState(() => _date = value);
  }

  Future<void> _save(AppData data) async {
    if (_workshopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر الورشة أولاً')));
      return;
    }
    if (_rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر عاملاً واحداً على الأقل')));
      return;
    }
    final workshop = data.workshopById(_workshopId!);
    if (workshop == null) return;
    setState(() => _saving = true);
    try {
      for (final row in _rows.values) {
        final worker = data.workerById(row.workerId);
        if (worker == null) continue;
        await data.addJournalEntry(
          workerName: worker.name,
          workshopName: workshop.name,
          wage: row.n(row.wage),
          workFraction: row.fraction,
          overtimeHours: row.n(row.overtimeHours),
          overtimeRate: row.n(row.overtimeRate),
          deduction: row.n(row.deduction),
          date: _date,
          present: row.present,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل يوميات العمال بنجاح')));
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final total = _rows.values.fold<double>(0, (sum, row) => sum + row.total);
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل يوميات جماعي'), actions: [IconButton(onPressed: _pickDate, icon: const Icon(Icons.calendar_month_outlined))]),
      body: data.workers.isEmpty
          ? const Center(child: Text('أضف العمال أولاً'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: const Text('تاريخ اليومية', style: TextStyle(fontWeight: FontWeight.w700)),
                        trailing: Text(Formatters.date(_date)),
                        onTap: _pickDate,
                      ),
                      DropdownButtonFormField<String>(
                        value: _workshopId,
                        decoration: const InputDecoration(labelText: 'الورشة', prefixIcon: Icon(Icons.architecture_outlined)),
                        items: data.workshops.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
                        onChanged: (v) => setState(() => _workshopId = v),
                      ),
                      Row(children: [
                        const Expanded(child: Text('العمال', style: TextStyle(fontWeight: FontWeight.w800))),
                        TextButton(onPressed: () => setState(() {
                          for (final w in data.workers) { _rows[w.id] ??= _BatchRow(w.id, 0); }
                        }), child: const Text('تحديد الكل')),
                        TextButton(onPressed: () => setState(() {
                          for (final row in _rows.values) row.dispose();
                          _rows.clear();
                        }), child: const Text('مسح')),
                      ]),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                ...data.workers.map((worker) {
                  final selected = _rows.containsKey(worker.id);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      initiallyExpanded: selected,
                      leading: Checkbox(
                        value: selected,
                        onChanged: (value) => setState(() {
                          if (value == true) { _rows[worker.id] = _BatchRow(worker.id, 0); }
                          else { _rows.remove(worker.id)?.dispose(); }
                        }),
                      ),
                      title: Text(worker.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(worker.profession.isEmpty ? 'عامل' : worker.profession),
                      children: selected ? [_Editor(row: _rows[worker.id]!, currency: data.currencySymbol, onChanged: () => setState(() {}))] : const [],
                    ),
                  );
                }),
              ],
            ),
      bottomSheet: SafeArea(
        child: Material(
          elevation: 8,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(children: [
              Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('إجمالي اليوميات المحددة', style: TextStyle(fontSize: 12)),
                Text(Formatters.currency(total, data.currencySymbol), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              ])),
              FilledButton.icon(
                onPressed: _saving ? null : () => _save(data),
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                label: const Text('حفظ الكل'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Editor extends StatelessWidget {
  final _BatchRow row;
  final String currency;
  final VoidCallback onChanged;
  const _Editor({required this.row, required this.currency, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    InputDecoration d(String label) => InputDecoration(labelText: label, isDense: true);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('حاضر'),
          value: row.present,
          onChanged: (v) { row.present = v; onChanged(); },
        ),
        Row(children: [
          Expanded(child: TextField(controller: row.wage, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: d('اليومية (' + currency + ')'), onChanged: (_) => onChanged())),
          const SizedBox(width: 10),
          Expanded(child: DropdownButtonFormField<double>(
            value: row.fraction,
            decoration: d('الدوام'),
            items: const [DropdownMenuItem(value: 1, child: Text('كامل')), DropdownMenuItem(value: .5, child: Text('نصف'))],
            onChanged: (v) { row.fraction = v ?? 1; onChanged(); },
          )),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: row.overtimeHours, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: d('إضافي / ساعة'), onChanged: (_) => onChanged())),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: row.overtimeRate, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: d('سعر الساعة'), onChanged: (_) => onChanged())),
        ]),
        const SizedBox(height: 10),
        TextField(controller: row.deduction, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: d('الخصم'), onChanged: (_) => onChanged()),
        const SizedBox(height: 10),
        Align(alignment: AlignmentDirectional.centerEnd, child: Text('المحتسب: ' + Formatters.currency(row.total, currency), style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w800))),
      ]),
    );
  }
}
