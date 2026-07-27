import '../l10n/app_localizations.dart';

enum PaymentType { weekly, advance, settlement, other }

extension PaymentTypeX on PaymentType {
  String get label {
    switch (this) {
      case PaymentType.weekly:
        return 'دفعة أسبوعية';
      case PaymentType.advance:
        return 'سلفة نقدية';
      case PaymentType.settlement:
        return 'تسوية حساب';
      case PaymentType.other:
        return 'أخرى';
    }
  }

  String labelFor(AppLanguage lang) {
    const en = {
      PaymentType.weekly: 'Weekly payment',
      PaymentType.advance: 'Cash advance',
      PaymentType.settlement: 'Settlement',
      PaymentType.other: 'Other',
    };
    const tr = {
      PaymentType.weekly: 'Haftalık ödeme',
      PaymentType.advance: 'Nakit avans',
      PaymentType.settlement: 'Hesap kapatma',
      PaymentType.other: 'Diğer',
    };
    switch (lang) {
      case AppLanguage.en:
        return en[this]!;
      case AppLanguage.tr:
        return tr[this]!;
      case AppLanguage.ar:
        return label;
    }
  }

  static PaymentType fromString(String v) {
    switch (v) {
      case 'weekly':
        return PaymentType.weekly;
      case 'advance':
        return PaymentType.advance;
      case 'settlement':
        return PaymentType.settlement;
      default:
        return PaymentType.other;
    }
  }
}

/// A payment made to a worker (advance, weekly pay, or settlement).
/// This decreases the amount owed to the worker.
class Payment {
  final String id;
  String workerId;
  DateTime date;
  double amount;
  PaymentType type;
  String notes;
  DateTime createdAt;

  Payment({
    required this.id,
    required this.workerId,
    required this.date,
    required this.amount,
    this.type = PaymentType.advance,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'worker_id': workerId,
        'date': date.toIso8601String(),
        'amount': amount,
        'type': type.name,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
        id: map['id'] as String,
        workerId: map['worker_id'] as String,
        date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
        amount: (map['amount'] as num).toDouble(),
        type: PaymentTypeX.fromString(map['type'] as String? ?? 'advance'),
        notes: map['notes'] as String? ?? '',
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
