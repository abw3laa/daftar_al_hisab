class Worker {
  final String id;
  String name;
  String profession;
  String phone;
  String? defaultWorkshopId;
  DateTime createdAt;

  Worker({
    required this.id,
    required this.name,
    this.profession = '',
    this.phone = '',
    this.defaultWorkshopId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'profession': profession,
        'phone': phone,
        'default_workshop_id': defaultWorkshopId,
        'created_at': createdAt.toIso8601String(),
      };

  factory Worker.fromMap(Map<String, dynamic> map) => Worker(
        id: map['id'] as String,
        name: map['name'] as String,
        profession: map['profession'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        defaultWorkshopId: map['default_workshop_id'] as String?,
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  String get initial => name.trim().isNotEmpty ? name.trim()[0] : '؟';
}
