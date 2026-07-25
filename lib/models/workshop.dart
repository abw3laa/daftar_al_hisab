enum WorkshopStatus { active, partiallyDone, completed }

extension WorkshopStatusX on WorkshopStatus {
  String get label {
    switch (this) {
      case WorkshopStatus.active:
        return 'نشط';
      case WorkshopStatus.partiallyDone:
        return 'مكتمل جزئياً';
      case WorkshopStatus.completed:
        return 'مكتمل';
    }
  }

  static WorkshopStatus fromString(String v) {
    switch (v) {
      case 'active':
        return WorkshopStatus.active;
      case 'partiallyDone':
        return WorkshopStatus.partiallyDone;
      case 'completed':
        return WorkshopStatus.completed;
      default:
        return WorkshopStatus.active;
    }
  }
}

class Workshop {
  final String id;
  String name;
  String location;
  WorkshopStatus status;
  DateTime createdAt;

  Workshop({
    required this.id,
    required this.name,
    this.location = '',
    this.status = WorkshopStatus.active,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'location': location,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
      };

  factory Workshop.fromMap(Map<String, dynamic> map) => Workshop(
        id: map['id'] as String,
        name: map['name'] as String,
        location: map['location'] as String? ?? '',
        status: WorkshopStatusX.fromString(map['status'] as String? ?? 'active'),
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
