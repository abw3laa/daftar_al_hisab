import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_data.dart';
import '../utils/formatters.dart';

class AddJournalScreen extends StatefulWidget {
  final DateTime? initialDate;

  /// When set, the worker-name field is pre-filled and locked (used in
  /// worker mode, where the logged-in worker only ever logs their own
  /// work).
  final String? lockedWorkerName;

  const AddJournalScreen({super.key, this.initialDate, this.lockedWorkerName});

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

  bool get _isLocked => widget.lockedWorkerName != null;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    if (widget.lockedWorkerName != null) {
      _workerController.text = widget.lockedWorkerName!;
    }
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
    final ar = data.language == AppLanguage.ar;
    final tr = data.language == AppLanguage.tr;
    final requiredMsg = ar
        ? 'هذا الحقل مطلوب'
        : tr
            ? 'Bu alan zorunludur'
            : 'This field is required';
    final invalidNumberMsg = ar
        ? 'رقم غير صالح'
        : tr
            ? 'Geçersiz sayı'
            : 'Invalid number';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.edit_document, size: 20),
            const SizedBox(width: 8),
            Text(data.t('record_journal')),
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
                decoration: InputDecoration(
                  labelText: data.t('date'),
                  suffixIcon: const Icon(Icons.calendar_today, size: 18),
                ),
                child: Text(Formatters.date(_date)),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLocked)
              TextFormField(
                controller: _workerController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: data.t('worker_name'),
                  suffixIcon: const Icon(Icons.lock_outline, size: 18),
                ),
              )
            else
              Autocomplete<String>(
                optionsBuilder: (value) {
                  if (value.text.isEmpty) return const Iterable.empty();
                  return data.workers
                      .map((w) => w.name)
                      .where((n) =>
                          n.toLowerCase().contains(value.text.toLowerCase()));
                },
                onSelected: (v) => _workerController.text = v,
                fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                  controller.text = _workerController.text;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (v) => _workerController.text = v,
                    decoration: InputDecoration(
                      labelText: data.t('worker_name'),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? requiredMsg : null,
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
                  decoration: InputDecoration(
                    labelText: data.t('workshop_name'),
                    helperText: ar
                        ? 'سيتم إنشاء ورشة جديدة تلقائياً إذا لم تكن موجودة'
                        : tr
                            ? 'Mevcut değilse otomatik olarak yeni bir atölye oluşturulacaktır'
                            : "A new workshop will be created automatically if it doesn't exist",
                    helperMaxLines: 2,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? requiredMsg : null,
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _wageController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: data.t('daily_wage'),
                suffixText: data.currencySymbol,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return requiredMsg;
                if (double.tryParse(v.trim()) == null) return invalidNumberMsg;
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(labelText: data.t('notes_optional')),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _present,
              onChanged: (v) => setState(() => _present = v),
              title: Text(data.t('worker_present')),
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
              label: Text(data.t('save_and_record')),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(data.t('cancel')),
            ),
          ],
        ),
      ),
    );
  }
}
