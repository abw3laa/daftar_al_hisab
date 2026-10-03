import 'package:flutter_test/flutter_test.dart';
import 'package:daftar_al_hisab/models/journal_entry.dart';

void main() {
  group('accounting calculations', () {
    test('full day plus overtime minus deduction', () {
      final entry = JournalEntry(
        id: '1',
        workerId: 'w1',
        workshopId: 's1',
        date: DateTime(2026, 1, 1),
        wage: 500,
        workFraction: 1,
        overtimeHours: 2,
        overtimeRate: 75,
        deduction: 50,
      );
      expect(entry.baseWage, 500);
      expect(entry.overtimeAmount, 150);
      expect(entry.calculatedWage, 600);
    });

    test('half day is calculated from base wage', () {
      final entry = JournalEntry(
        id: '2',
        workerId: 'w1',
        workshopId: 's1',
        date: DateTime(2026, 1, 1),
        wage: 500,
        workFraction: .5,
      );
      expect(entry.calculatedWage, 250);
    });

    test('absence produces zero wage', () {
      final entry = JournalEntry(
        id: '3',
        workerId: 'w1',
        workshopId: 's1',
        date: DateTime(2026, 1, 1),
        wage: 500,
        present: false,
        overtimeHours: 4,
        overtimeRate: 100,
      );
      expect(entry.calculatedWage, 0);
    });

    test('negative result is clamped to zero', () {
      final entry = JournalEntry(
        id: '4',
        workerId: 'w1',
        workshopId: 's1',
        date: DateTime(2026, 1, 1),
        wage: 500,
        deduction: 900,
      );
      expect(entry.calculatedWage, 0);
    });
  });
}
