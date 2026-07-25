import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workshop.dart';
import '../providers/app_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/summary_card.dart';
import '../widgets/worker_avatar.dart';
import 'worker_profile_screen.dart';

class WorkshopDetailScreen extends StatelessWidget {
  final String workshopId;
  const WorkshopDetailScreen({super.key, required this.workshopId});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppData>(
      builder: (context, data, _) {
        final workshop = data.workshopById(workshopId);
        if (workshop == null) {
          return const Scaffold(body: Center(child: Text('لم يتم العثور على الورشة')));
        }
        final entries = data.entriesForWorkshop(workshopId)
          ..sort((a, b) => b.date.compareTo(a.date));
        final cost = data.totalCostForWorkshop(workshopId);
        final workerIds = entries.map((e) => e.workerId).toSet();

        return Scaffold(
          appBar: AppBar(
            title: Text(workshop.name),
            actions: [
              PopupMenuButton<WorkshopStatus>(
                onSelected: (status) {
                  workshop.status = status;
                  data.updateWorkshop(workshop);
                },
                itemBuilder: (context) => WorkshopStatus.values
                    .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
                    .toList(),
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
                      label: 'أيام العمل',
                      value: '${entries.length}',
                      positive: true,
                      icon: Icons.engineering,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      label: 'التكلفة الإجمالية',
                      value: Formatters.currency(cost, data.currencySymbol),
                      positive: false,
                      icon: Icons.payments,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('العمال في هذه الورشة (${workerIds.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              ...workerIds.map((id) {
                final worker = data.workerById(id);
                if (worker == null) return const SizedBox.shrink();
                final workerEntries =
                    entries.where((e) => e.workerId == id).toList();
                final workerCost =
                    workerEntries.fold(0.0, (s, e) => s + e.wage);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: WorkerAvatar(initial: worker.initial),
                    title: Text(worker.name),
                    subtitle: Text('${workerEntries.length} يوم عمل • ${worker.profession}'),
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
              Text('سجل اليوميات', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              ...entries.map((e) {
                final worker = data.workerById(e.workerId);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.work, color: AppColors.secondary),
                  title: Text(worker?.name ?? 'عامل محذوف'),
                  subtitle: Text(Formatters.dateLongArabic(e.date)),
                  trailing: Text(
                    '+${Formatters.amount(e.wage)}',
                    style: const TextStyle(
                        color: AppColors.secondary, fontWeight: FontWeight.w700),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
