import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/summary_card.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppData>(
      builder: (context, data, _) {
        final workshopStats = data.workshops.map((w) {
          return MapEntry(w, data.totalCostForWorkshop(w.id));
        }).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final maxCost = workshopStats.isEmpty
            ? 1.0
            : workshopStats.map((e) => e.value).reduce((a, b) => a > b ? a : b);

        return Scaffold(
          appBar: AppBar(title: Text(data.t('drawer_reports'))),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      label: data.t('total_owed_to_workers'),
                      value: Formatters.currency(
                          data.totalOwedToAllWorkers, data.currencySymbol),
                      positive: true,
                      icon: Icons.group,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      label: data.t('wages_this_month'),
                      value: Formatters.currency(
                          data.totalWagesThisMonth, data.currencySymbol),
                      positive: false,
                      icon: Icons.calendar_month,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(data.t('cost_by_workshop'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 16),
              if (workshopStats.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(data.t('not_enough_data'),
                        style: TextStyle(color: Colors.grey.shade600)),
                  ),
                )
              else
                ...workshopStats.map((entry) {
                  final ratio = maxCost == 0 ? 0.0 : entry.value / maxCost;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key.name,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(Formatters.currency(entry.value, data.currencySymbol)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: ratio.clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: const Color(0xFFE2E7FF),
                            valueColor:
                                const AlwaysStoppedAnimation(AppColors.secondary),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 24),
              Text(data.t('top_owed_workers'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              ...(data.workers.map((w) => MapEntry(w, data.balanceForWorker(w.id))).toList()
                    ..sort((a, b) => b.value.compareTo(a.value)))
                  .take(5)
                  .map((entry) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.key.name),
                        trailing: Text(
                          Formatters.currency(entry.value, data.currencySymbol),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: entry.value >= 0
                                ? AppColors.secondary
                                : AppColors.error,
                          ),
                        ),
                      )),
            ],
          ),
        );
      },
    );
  }
}
