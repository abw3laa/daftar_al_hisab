/// سجل يوم عمل لعامل في ورشة محددة.
///
/// `wage` هو أجر اليوم الكامل الأساسي. أما `calculatedWage` فهو المبلغ
/// النهائي الذي يدخل في الحساب بعد تطبيق نسبة اليوم، الساعات الإضافية والخصم.
class JournalEntry {
  final String id;
  String workerId;
  String workshopId;
  DateTime date;
  double wage;
  double workFraction;
  double overtimeHours;
  double overtimeRate;
  double deduction;
  String notes;
  bool present;
  DateTime createdAt;

  JournalEntry({
    required this.id,
    required this.workerId,
    required this.workshopId,
    required this.date,
    required this.wage,
    this.workFraction = 1.0,
    this.overtimeHours = 0.0,
    this.overtimeRate = 0.0,
    this.deduction = 0.0,
    this.notes = '',
    this.present = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get baseWage => wage * workFraction;

  double get overtimeAmount => overtimeHours * overtimeRate;

  double get calculatedWage {
    if (!present) return 0.0;
    final value = baseWage + overtimeAmount - deduction;
    return value < 0 ? 0.0 : value;
  }

  String get workFractionLabel {
    if (workFraction == 0.5) return 'نصف يوم';
    if (workFraction == 1.0) return 'يوم كامل';
    return '${(workFraction * 100).round()}%';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'worker_id': workerId,
        'workshop_id': workshopId,
        'date': date.toIso8601String(),
        'wage': wage,
        'work_fraction': workFraction,
        'overtime_hours': overtimeHours,
        'overtime_rate': overtimeRate,
        'deduction': deduction,
        'notes': notes,
        'present': present ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory JournalEntry.fromMap(Map<String, dynamic> map) => JournalEntry(
        id: map['id'] as String,
        workerId: map['worker_id'] as String,
        workshopId: map['workshop_id'] as String,
        date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
        wage: (map['wage'] as num? ?? 0).toDouble(),
        workFraction: (map['work_fraction'] as num? ?? 1).toDouble(),
        overtimeHours: (map['overtime_hours'] as num? ?? 0).toDouble(),
        overtimeRate: (map['overtime_rate'] as num? ?? 0).toDouble(),
        deduction: (map['deduction'] as num? ?? 0).toDouble(),
        notes: map['notes'] as String? ?? '',
        present: (map['present'] as num? ?? 1).toInt() == 1,
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
