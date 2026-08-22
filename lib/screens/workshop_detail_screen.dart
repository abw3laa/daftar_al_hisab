import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../models/workshop.dart';
import '../providers/app_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/summary_card.dart';
import '../widgets/worker_avatar.dart';
import 'add_journal_screen.dart';
import 'worker_profile_screen.dart';

class WorkshopDetailScreen extends StatelessWidget {
  final String workshopId;
  const WorkshopDetailScreen({super.key, required this.workshopId});

  Future<void> _showEditDialog(
      BuildContext context, AppData data, Workshop workshop) async {
    final nameController = TextEditingController(text: workshop.name);
    final locationController = TextEditingController(text: workshop.location);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data.t('edit')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: data.t('workshop_name')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              decoration: InputDecoration(labelText: data.t('location')),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(data.t('cancel'))),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              workshop.name = nameController.text.trim();
              workshop.location = locationController.text.trim();
              await data.updateWorkshop(workshop);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(data.t('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppData data, Workshop workshop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data.t('delete')),
        content: Text(data.language == AppLanguage.ar
            ? 'سيتم حذف الورشة وكل سجلات اليوميات المرتبطة بها نهائياً. هل أنت متأكد؟'
            : data.language == AppLanguage.tr
                ? 'Atölye ve ilişkili tüm günlük kayıtları kalıcı olarak silinecek. Emin misiniz?'
                : 'This will permanently delete the workshop and all its journal entries. Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(data.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(data.t('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await data.deleteWorkshop(workshop.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppData>(
      builder: (context, data, _) {
        final workshop = data.workshopById(workshopId);
        if (workshop == null) {
          return Scaffold(
              body: Center(
                  child: Text(data.language == AppLanguage.ar
                      ? 'لم يتم العثور على الورشة'
                      : data.language == AppLanguage.tr
                          ? 'Atölye bulunamadı'
                          : 'Workshop not found')));
        }
        final entries = data.entriesForWorkshop(workshopId)
          ..sort((a, b) => b.date.compareTo(a.date));
        final cost = data.totalCostForWorkshop(workshopId);
        final workerIds = entries.map((e) => e.workerId).toSet();

        return Scaffold(
          appBar: AppBar(
            title: Text(workshop.name),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    await _showEditDialog(context, data, workshop);
                  } else if (value == 'delete') {
                    await _confirmDelete(context, data, workshop);
                  } else {
                    workshop.status = WorkshopStatusX.fromString(value);
                    data.updateWorkshop(workshop);
                  }
                },
                itemBuilder: (context) => [
                  ...WorkshopStatus.values
                      .map((s) => PopupMenuItem(value: s.name, child: Text(s.label))),
                  const PopupMenuDivider(),
                  PopupMenuItem(value: 'edit', child: Text(data.t('edit'))),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(data.t('delete'),
                        style: const TextStyle(color: Colors.red)),
                  ),
                ],
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (workshop.location.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(workshop.location,
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      label: data.t('total_work_days'),
                      value: '${entries.length}',
                      positive: true,
                      icon: Icons.engineering,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      label: data.t('total_cost'),
                      value: Formatters.currency(cost, data.currencySymbol),
                      positive: false,
                      icon: Icons.payments,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('${data.t('workers_in_workshop')} (${workerIds.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              ...workerIds.map((id) {
                final worker = data.workerById(id);
                if (worker == null) return const SizedBox.shrink();
                final workerEntries =
                    entries.where((e) => e.workerId == id).toList();
                final workerCost =
                    workerEntries.fold(0.0, (s, e) => s + e.calculatedWage);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: WorkerAvatar(initial: worker.initial),
                    title: Text(worker.name),
                    subtitle: Text('${workerEntries.length} • ${worker.profession}'),
                    trailing: Text(
                      Formatters.currency(workerCost, data.currencySymbol),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => WorkerProfileScreen(workerId: worker.id)),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              Text(data.t('journal_log'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              ...entries.map((e) => _WorkshopJournalTile(entry: e, data: data)),
            ],
          ),
        );
      },
    );
  }
}


class _WorkshopJournalTile extends StatelessWidget {
  final JournalEntry entry;
  final AppData data;

  const _WorkshopJournalTile({required this.entry, required this.data});

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data.t('delete')),
        content: Text(data.language == AppLanguage.ar
            ? 'سيتم حذف يومية العمل نهائيًا.'
            : data.language == AppLanguage.tr
                ? 'Çalışma kaydı kalıcı olarak silinecek.'
                : 'This work entry will be permanently deleted.'),
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
    if (confirmed == true) await data.deleteJournalEntry(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    final worker = data.workerById(entry.workerId);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.work_outline, color: AppColors.secondary),
      title: Text(worker?.name ??
          (data.language == AppLanguage.ar ? 'عامل محذوف' : 'Deleted worker')),
      subtitle: Text(Formatters.dateLongArabic(entry.date)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('+${Formatters.amount(entry.calculatedWage)}',
            style: const TextStyle(
                color: AppColors.secondary, fontWeight: FontWeight.w700)),
        PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AddJournalScreen(initialEntry: entry)),
              );
            } else {
              await _delete(context);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(data.t('edit'))),
            PopupMenuItem(value: 'delete', child: Text(data.t('delete'))),
          ],
        ),
      ]),
    );
  }
}
