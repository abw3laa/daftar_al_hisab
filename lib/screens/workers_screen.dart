import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/worker.dart';
import '../providers/app_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/worker_avatar.dart';
import 'worker_profile_screen.dart';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppData>(
      builder: (context, data, _) {
        final workers = data.workers
            .where((w) => w.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: data.reloadAll,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'بحث عن عامل',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),
                if (workers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Text('لا يوجد عمال بعد',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  )
                else
                  ...workers.map((w) => _WorkerTile(worker: w)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddWorkerDialog(context),
            icon: const Icon(Icons.person_add),
            label: const Text('عامل جديد'),
          ),
        );
      },
    );
  }

  Future<void> _showAddWorkerDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final professionController = TextEditingController();
    final phoneController = TextEditingController();
    final data = context.read<AppData>();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('عامل جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'الاسم'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: professionController,
              decoration: const InputDecoration(labelText: 'المهنة'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم الهاتف (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              await data.findOrCreateWorkerByName(
                nameController.text.trim(),
                profession: professionController.text.trim(),
              );
              if (phoneController.text.trim().isNotEmpty) {
                final w = data.workers.firstWhere(
                    (w) => w.name.trim() == nameController.text.trim());
                w.phone = phoneController.text.trim();
                await data.updateWorker(w);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

class _WorkerTile extends StatelessWidget {
  final Worker worker;
  const _WorkerTile({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppData>(
      builder: (context, data, _) {
        final balance = data.balanceForWorker(worker.id);
        final isOwed = balance >= 0;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            minVerticalPadding: 16,
            leading: WorkerAvatar(initial: worker.initial),
            title: Text(worker.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(worker.profession.isNotEmpty ? worker.profession : '—'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Formatters.currency(balance.abs(), data.currencySymbol),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isOwed ? AppColors.secondary : AppColors.error,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_left),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => WorkerProfileScreen(workerId: worker.id)),
            ),
          ),
        );
      },
    );
  }
}
