import 'package:flutter/material.dart';

import '../theme/template_spacing.dart';

class TemplateAddTransactionScreen extends StatefulWidget {
  const TemplateAddTransactionScreen({super.key});

  @override
  State<TemplateAddTransactionScreen> createState() => _TemplateAddTransactionScreenState();
}

class _TemplateAddTransactionScreenState extends State<TemplateAddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _type = 'إضافة';

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة حركة')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(TemplateSpacing.lg),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'إضافة', label: Text('إضافة')),
                ButtonSegment(value: 'خصم', label: Text('خصم')),
              ],
              selected: {_type},
              onSelectionChanged: (value) => setState(() => _type = value.first),
            ),
            const SizedBox(height: TemplateSpacing.lg),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'المبلغ'),
              validator: (value) => value == null || value.trim().isEmpty ? 'أدخل المبلغ' : null,
            ),
            const SizedBox(height: TemplateSpacing.md),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'ملاحظة'),
            ),
            const SizedBox(height: TemplateSpacing.xl),
            FilledButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
