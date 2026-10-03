class PayrollPeriod {
  final String id;
  final int year;
  final int month;
  String status;
  String notes;
  final DateTime createdAt;
  DateTime? closedAt;

  PayrollPeriod({required this.id, required this.year, required this.month, this.status = 'open', this.notes = '', DateTime? createdAt, this.closedAt}) : createdAt = createdAt ?? DateTime.now();
  bool get isClosed => status == 'closed';
  String get label => '$year-${month.toString().padLeft(2, '0')}';
  Map<String, dynamic> toMap() => {'id': id, 'year': year, 'month': month, 'status': status, 'notes': notes, 'created_at': createdAt.toIso8601String(), 'closed_at': closedAt?.toIso8601String()};
  factory PayrollPeriod.fromMap(Map<String, dynamic> map) => PayrollPeriod(id: map['id'] as String, year: (map['year'] as num).toInt(), month: (map['month'] as num).toInt(), status: map['status'] as String? ?? 'open', notes: map['notes'] as String? ?? '', createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(), closedAt: map['closed_at'] == null ? null : DateTime.tryParse(map['closed_at'] as String));
}
