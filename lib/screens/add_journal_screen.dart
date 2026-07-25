import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_data.dart';
import '../utils/formatters.dart';

class AddJournalScreen extends StatefulWidget {
  final DateTime? initialDate;
  const AddJournalScreen({super.key, this.initialDate});

  @override
  State<AddJournalScreen> createState() => _AddJournalScreenState();
}

class _AddJournalScreenState extends State<AddJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workerController = TextEditingController();
  final _workshopController = TextEditingController();
  final _wageController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _date;
  bool _present = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _workerController.dispose();
    _workshopController.dispose();
    _wageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = context.read<AppData>();
    await data.addJournalEntry(
      workerName: _workerController.text.trim(),
      workshopName: _workshopController.text.trim(),
      wage: double.parse(_wageController.text.trim()),
      notes: _notesController.text.trim(),
      date: _date,
      present: _present,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.edit_document, size: 20),
            SizedBox(width: 8),
            Text('تسجيل يومية'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'التاريخ',
                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                ),
                child: Text(Formatters.date(_date)),
              ),
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              optionsBuilder: (value) {
                if (value.text.isEmpty) return const Iterable.empty();
                return data.workers
                    .map((w) => w.name)
                    .where((n) => n.toLowerCase().contains(value.text.toLowerCase()));
              },
              onSelected: (v) => _workerController.text = v,
              fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                controller.text = _workerController.text;
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: (v) => _workerController.text = v,
                  decoration: const InputDecoration(
                    labelText: 'اسم العامل',
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'الرجاء إدخال اسم العامل' : null,
                );
              },
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              optionsBuilder: (value) {
                if (value.text.isEmpty) return const Iterable.empty();
                return data.workshops
                    .map((w) => w.name)
                    .where((n) => n.toLowerCase().contains(value.text.toLowerCase()));
              },
              onSelected: (v) => _workshopController.text = v,
              fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                controller.text = _workshopController.text;
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: (v) => _workshopController.text = v,
                  decoration: const InputDecoration(
                    labelText: 'اسم الورشة / موقع العمل',
                    helperText:
                        'سيتم إنشاء ورشة جديدة تلقائياً إذا لم تكن موجودة',
                    helperMaxLines: 2,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'الرجاء إدخال اسم الورشة' : null,
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _wageController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'أجر اليوم / اليومية',
                suffixText: data.currencySymbol,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'الرجاء إدخال الأجر';
                if (double.tryParse(v.trim()) == null) return 'رقم غير صالح';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _present,
              onChanged: (v) => setState(() => _present = v),
              title: const Text('العامل حاضر / تم إنجاز العمل'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: const Text('حفظ وتسجيل'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    );
  }
}
