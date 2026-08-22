import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../providers/app_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class AddJournalScreen extends StatefulWidget {
  final DateTime? initialDate;
  final String? lockedWorkerName;
  final JournalEntry? initialEntry;

  const AddJournalScreen({
    super.key,
    this.initialDate,
    this.lockedWorkerName,
    this.initialEntry,
  });

  bool get isEditing => initialEntry != null;

  @override
  State<AddJournalScreen> createState() => _AddJournalScreenState();
}

class _AddJournalScreenState extends State<AddJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workerController = TextEditingController();
  final _workshopController = TextEditingController();
  final _wageController = TextEditingController();
  final _overtimeHoursController = TextEditingController();
  final _overtimeRateController = TextEditingController();
  final _deductionController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _date;
  double _workFraction = 1.0;
  bool _present = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    _date = entry?.date ?? widget.initialDate ?? DateTime.now();
    if (entry != null) {
      final data = context.read<AppData>();
      _workerController.text = data.workerById(entry.workerId)?.name ?? '';
      _workshopController.text = data.workshopById(entry.workshopId)?.name ?? '';
      _wageController.text = _number(entry.wage);
      _workFraction = entry.workFraction;
      _overtimeHoursController.text = _number(entry.overtimeHours);
      _overtimeRateController.text = _number(entry.overtimeRate);
      _deductionController.text = _number(entry.deduction);
      _notesController.text = entry.notes;
      _present = entry.present;
    } else if (widget.lockedWorkerName != null) {
      _workerController.text = widget.lockedWorkerName!;
    }
  }

  String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);

  @override
  void dispose() {
    _workerController.dispose();
    _workshopController.dispose();
    _wageController.dispose();
    _overtimeHoursController.dispose();
    _overtimeRateController.dispose();
    _deductionController.dispose();
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

  double _parse(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;

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

  String? _required(String? value, AppData data) =>
      value == null || value.trim().isEmpty
          ? _localized(data, 'هذا الحقل مطلوب', 'This field is required',
              'Bu alan zorunludur')
          : null;

  String? _nonNegative(String? value, AppData data, {required bool required}) {
    if (value == null || value.trim().isEmpty) {
      return required ? _required(value, data) : null;
    }
    final number = double.tryParse(value.trim().replaceAll(',', '.'));
    if (number == null || number < 0) {
      return _localized(data, 'أدخل رقمًا صالحًا غير سالب',
          'Enter a valid non-negative number', 'Geçerli ve negatif olmayan bir sayı girin');
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = context.read<AppData>();
    final wage = _parse(_wageController);
    final overtimeHours = _parse(_overtimeHoursController);
    final overtimeRate = _parse(_overtimeRateController);
    final deduction = _parse(_deductionController);

    try {
      if (widget.isEditing) {
        final entry = widget.initialEntry!;
        final worker = await data.findOrCreateWorkerByName(
          _workerController.text.trim(),
        );
        final workshop = await data.findOrCreateWorkshopByName(
          _workshopController.text.trim(),
        );
        entry
          ..workerId = worker.id
          ..workshopId = workshop.id
          ..date = _date
          ..wage = wage
          ..workFraction = _workFraction
          ..overtimeHours = overtimeHours
          ..overtimeRate = overtimeRate
          ..deduction = deduction
          ..notes = _notesController.text.trim()
          ..present = _present;
        await data.updateJournalEntry(entry);
      } else {
        await data.addJournalEntry(
          workerName: _workerController.text.trim(),
          workshopName: _workshopController.text.trim(),
          wage: wage,
          workFraction: _workFraction,
          overtimeHours: overtimeHours,
          overtimeRate: overtimeRate,
          deduction: deduction,
          notes: _notesController.text.trim(),
          date: _date,
          present: _present,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final isLocked = widget.lockedWorkerName != null && !widget.isEditing;
    final base = _parse(_wageController) * _workFraction;
    final overtime = _parse(_overtimeHoursController) *
        _parse(_overtimeRateController);
    final total = (base + overtime - _parse(_deductionController))
        .clamp(0.0, double.infinity)
        .toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing
            ? _localized(data, 'تعديل يومية', 'Edit work day', 'Günü düzenle')
            : data.t('record_journal')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _SectionTitle(
              icon: Icons.event_outlined,
              title: _localized(data, 'بيانات العمل', 'Work details', 'İş bilgileri'),
            ),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: data.t('date'),
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(Formatters.date(_date)),
              ),
            ),
            const SizedBox(height: 14),
            if (isLocked)
              TextFormField(
                controller: _workerController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: data.t('worker_name'),
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: const Icon(Icons.lock_outline, size: 18),
                ),
                validator: (v) => _required(v, data),
              )
            else
              _autocompleteField(
                controller: _workerController,
                label: data.t('worker_name'),
                icon: Icons.person_outline,
                options: data.workers.map((w) => w.name),
                validator: (v) => _required(v, data),
              ),
            const SizedBox(height: 14),
            _autocompleteField(
              controller: _workshopController,
              label: data.t('workshop_name'),
              icon: Icons.location_city_outlined,
              options: data.workshops.map((w) => w.name),
              validator: (v) => _required(v, data),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _wageController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: data.t('daily_wage'),
                prefixIcon: const Icon(Icons.payments_outlined),
                suffixText: data.currencySymbol,
              ),
              validator: (v) => _nonNegative(v, data, required: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<double>(
              initialValue: _workFraction,
              decoration: InputDecoration(
                labelText: _localized(data, 'نسبة اليوم', 'Workday fraction',
                    'Çalışma günü oranı'),
                prefixIcon: const Icon(Icons.timelapse_outlined),
              ),
              items: [
                DropdownMenuItem(
                    value: 1.0,
                    child: Text(_localized(
                        data, 'يوم كامل', 'Full day', 'Tam gün'))),
                DropdownMenuItem(
                    value: 0.5,
                    child: Text(_localized(
                        data, 'نصف يوم', 'Half day', 'Yarım gün'))),
              ],
              onChanged: (v) => setState(() => _workFraction = v ?? 1.0),
            ),
            const SizedBox(height: 20),
            _SectionTitle(
              icon: Icons.add_chart_outlined,
              title: _localized(data, 'إضافات وخصومات', 'Adjustments', 'Ekler ve kesintiler'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _overtimeHoursController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _localized(data, 'ساعات إضافية', 'Overtime hours',
                          'Fazla mesai saati'),
                      suffixText: 'h',
                    ),
                    validator: (v) => _nonNegative(v, data, required: false),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _overtimeRateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _localized(data, 'أجر الساعة', 'Hourly rate',
                          'Saatlik ücret'),
                      suffixText: data.currencySymbol,
                    ),
                    validator: (v) => _nonNegative(v, data, required: false),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _deductionController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _localized(data, 'الخصم', 'Deduction', 'Kesinti'),
                prefixIcon: const Icon(Icons.remove_circle_outline),
                suffixText: data.currencySymbol,
              ),
              validator: (v) => _nonNegative(v, data, required: false),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: data.t('notes_optional'),
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 4),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _present,
              onChanged: (v) => setState(() => _present = v),
              secondary: Icon(_present ? Icons.check_circle : Icons.cancel,
                  color: _present ? AppColors.secondary : AppColors.error),
              title: Text(data.t('worker_present')),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              color: AppColors.secondaryContainer.withValues(alpha: 0.18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.calculate_outlined,
                        color: AppColors.secondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _localized(data, 'الأجر المحتسب', 'Calculated wage',
                            'Hesaplanan ücret'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      Formatters.currency(total, data.currencySymbol),
                      style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 17),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(widget.isEditing ? data.t('save') : data.t('save_and_record')),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: Text(data.t('cancel')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _autocompleteField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Iterable<String> options,
    required String? Function(String?) validator,
  }) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (value) {
        if (value.text.trim().isEmpty) return const Iterable.empty();
        final query = value.text.toLowerCase();
        return options.where((name) => name.toLowerCase().contains(query));
      },
      onSelected: (value) => controller.text = value,
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: fieldController,
          focusNode: focusNode,
          onChanged: (value) => controller.text = value,
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
          validator: validator,
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.secondary),
          const SizedBox(width: 8),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }
}
