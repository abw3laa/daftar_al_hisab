import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/journal_entry.dart';
import '../providers/app_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/worker_avatar.dart';
import 'add_journal_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _month;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selectedDate = DateTime(_month.year, _month.month, 1);
    });
  }

  String _monthTitle(AppData data) {
    const ar = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    const en = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    const tr = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    final names = data.language == AppLanguage.ar ? ar : data.language == AppLanguage.tr ? tr : en;
    return '${names[_month.month - 1]} ${_month.year}';
  }

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

  @override
  Widget build(BuildContext context) {
    return Consumer<AppData>(
      builder: (context, data, _) {
        final entries = data.entriesForDate(_selectedDate)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: data.reloadAll,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                Row(
                  children: [
                    IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
                    Expanded(child: Text(_monthTitle(data), textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                    IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
                    IconButton(
                      tooltip: 'Today',
                      onPressed: () => setState(() {
                        final now = DateTime.now();
                        _month = DateTime(now.year, now.month);
                        _selectedDate = now;
                      }),
                      icon: const Icon(Icons.today_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _CalendarGrid(
                  month: _month,
                  selectedDate: _selectedDate,
                  entriesForDate: data.entriesForDate,
                  onDaySelected: (date) => setState(() => _selectedDate = date),
                  language: data.language,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${Formatters.date(_selectedDate)} · ${_localized(data, 'أيام العمل', 'Work days', 'Çalışma günleri')}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddJournalScreen(initialDate: _selectedDate))),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (entries.isEmpty)
                  _EmptyDay(text: _localized(data, 'لا توجد يوميات لهذا اليوم', 'No work entries for this day', 'Bu gün için kayıt yok'))
                else
                  ...entries.map((entry) => _JournalCard(entry: entry)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddJournalScreen(initialDate: _selectedDate))),
            icon: const Icon(Icons.edit_calendar_outlined),
            label: Text(data.t('record_journal')),
          ),
        );
      },
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDate;
  final List<JournalEntry> Function(DateTime) entriesForDate;
  final ValueChanged<DateTime> onDaySelected;
  final AppLanguage language;

  const _CalendarGrid({required this.month, required this.selectedDate, required this.entriesForDate, required this.onDaySelected, required this.language});

  List<String> get _weekdays {
    if (language == AppLanguage.ar) return const ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    if (language == AppLanguage.tr) return const ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstDayOffset = DateTime(month.year, month.month, 1).weekday - 1;
    final totalCells = ((firstDayOffset + daysInMonth + 6) ~/ 7) * 7;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
        child: Column(
          children: [
            Row(children: _weekdays.map((day) => Expanded(child: Center(child: Text(day, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w700)))).toList()),
            const Divider(height: 18),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: 78, crossAxisSpacing: 3, mainAxisSpacing: 3),
              itemBuilder: (context, index) {
                if (index < firstDayOffset || index >= firstDayOffset + daysInMonth) return const SizedBox.shrink();
                final date = DateTime(month.year, month.month, index - firstDayOffset + 1);
                final entries = entriesForDate(date);
                final isSelected = date.year == selectedDate.year && date.month == selectedDate.month && date.day == selectedDate.day;
                final isToday = DateUtils.isSameDay(date, DateTime.now());
                final allPresent = entries.isNotEmpty && entries.every((e) => e.present);
                return InkWell(
                  onTap: () => onDaySelected(date),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : entries.isNotEmpty ? AppColors.secondaryContainer.withValues(alpha: 0.10) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? AppColors.primary : isToday ? AppColors.secondary : Colors.transparent, width: isSelected || isToday ? 1.5 : 1),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${date.day}', style: TextStyle(fontWeight: FontWeight.w800, color: date.weekday >= 6 ? AppColors.error : null)),
                      const SizedBox(height: 3),
                      if (entries.isEmpty) const Spacer() else ...[
                        Row(children: [Icon(allPresent ? Icons.check_circle : Icons.warning_amber_rounded, size: 13, color: allPresent ? AppColors.secondary : Colors.orange), const SizedBox(width: 3), Text('${entries.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))]),
                        const SizedBox(height: 2),
                        Text(entries.first.notes.isNotEmpty ? entries.first.notes : (entries.first.present ? '✓' : '×'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                      ],
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final JournalEntry entry;
  const _JournalCard({required this.entry});

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

  Future<void> _delete(BuildContext context, AppData data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data.t('delete')),
        content: Text(_localized(data, 'سيتم حذف يومية العمل نهائيًا.', 'This work entry will be permanently deleted.', 'Bu çalışma kaydı kalıcı olarak silinecek.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(data.t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(data.t('delete'))),
        ],
      ),
    );
    if (confirmed == true) await data.deleteJournalEntry(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.read<AppData>();
    final worker = data.workerById(entry.workerId);
    final workshop = data.workshopById(entry.workshopId);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: WorkerAvatar(initial: worker?.initial ?? '؟', size: 42),
        title: Text(worker?.name ?? '—', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${workshop?.name ?? '—'} · ${entry.workFractionLabel}${entry.notes.isNotEmpty ? '\n${entry.notes}' : ''}', maxLines: 2, overflow: TextOverflow.ellipsis),
        isThreeLine: entry.notes.isNotEmpty,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(Formatters.currency(entry.calculatedWage, data.currencySymbol), style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w800)),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => AddJournalScreen(initialEntry: entry)));
              } else {
                await _delete(context, data);
              }
            },
            itemBuilder: (_) => [PopupMenuItem(value: 'edit', child: Text(data.t('edit'))), PopupMenuItem(value: 'delete', child: Text(data.t('delete')))],
          ),
        ]),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  final String text;
  const _EmptyDay({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      alignment: Alignment.center,
      child: Column(children: [Icon(Icons.event_available_outlined, size: 42, color: Colors.grey.shade400), const SizedBox(height: 8), Text(text, style: TextStyle(color: Colors.grey.shade600))]),
    );
  }
}
