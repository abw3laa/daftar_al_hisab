/// A daily-work journal record: a worker did a day of work at a workshop
/// for a given wage. This increases the amount owed to the worker.
class JournalEntry {
  final String id;
  String workerId;
  String workshopId;
  DateTime date;
  double wage;
  String notes;
  bool present; // whether the worker showed up / is confirmed for that day
  DateTime createdAt;

  JournalEntry({
    required this.id,
    required this.workerId,
    required this.workshopId,
    required this.date,
    required this.wage,
    this.notes = '',
    this.present = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'worker_id': workerId,
        'workshop_id': workshopId,
        'date': date.toIso8601String(),
        'wage': wage,
        'notes': notes,
        'present': present ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory JournalEntry.fromMap(Map<String, dynamic> map) => JournalEntry(
        id: map['id'] as String,
        workerId: map['worker_id'] as String,
        workshopId: map['workshop_id'] as String,
        date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
        wage: (map['wage'] as num).toDouble(),
        notes: map['notes'] as String? ?? '',
        present: (map['present'] as int? ?? 1) == 1,
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
