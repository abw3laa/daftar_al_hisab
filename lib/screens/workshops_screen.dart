import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workshop.dart';
import '../providers/app_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'workshop_detail_screen.dart';

class WorkshopsScreen extends StatefulWidget {
  const WorkshopsScreen({super.key});

  @override
  State<WorkshopsScreen> createState() => _WorkshopsScreenState();
}

class _WorkshopsScreenState extends State<WorkshopsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppData>(
      builder: (context, data, _) {
        final workshops = data.workshops
            .where((w) => w.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: data.reloadAll,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  data.t('workshops_overview'),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: data.t('search'),
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),
                if (workshops.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Text(data.t('no_workshops_yet'),
                          style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  )
                else
                  ...workshops.map((w) => _WorkshopCard(workshop: w)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddWorkshopDialog(context),
            icon: const Icon(Icons.add),
            label: Text(data.t('new_project')),
          ),
        );
      },
    );
  }

  Future<void> _showAddWorkshopDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final data = context.read<AppData>();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data.t('new_workshop_title')),
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
              await data.findOrCreateWorkshopByName(
                nameController.text.trim(),
                location: locationController.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(data.t('add')),
          ),
        ],
      ),
    );
  }
}

class _WorkshopCard extends StatelessWidget {
  final Workshop workshop;
  const _WorkshopCard({required this.workshop});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppData>(
      builder: (context, data, _) {
        final days = data.totalWorkDaysForWorkshop(workshop.id);
        final cost = data.totalCostForWorkshop(workshop.id);
        final lastActivity = data.lastActivityForWorkshop(workshop.id);
        final isNegative = cost > 0; // cost is an expense to the owner

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      WorkshopDetailScreen(workshopId: workshop.id)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          workshop.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                      _StatusBadge(status: workshop.status),
                      const Icon(Icons.chevron_left),
                    ],
                  ),
                  if (workshop.location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(workshop.location,
                              style: TextStyle(color: Colors.grey.shade600)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.engineering,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('${data.t('total_work_days')}: $days',
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.payments,
                          size: 16,
                          color: isNegative
                              ? AppColors.error
                              : AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        '${data.t('total_cost')}: ${isNegative ? '-' : '+'}${Formatters.currency(cost, data.currencySymbol)}',
                        style: TextStyle(
                          color: isNegative
                              ? AppColors.error
                              : AppColors.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.history,
                          size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text('${data.t('last_activity')}: ${Formatters.relativeTime(lastActivity)}',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final WorkshopStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case WorkshopStatus.active:
        color = AppColors.secondary;
        break;
      case WorkshopStatus.partiallyDone:
        color = Colors.orange;
        break;
      case WorkshopStatus.completed:
        color = Colors.grey;
        break;
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
