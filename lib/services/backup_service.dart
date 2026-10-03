import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/journal_entry.dart';
import '../models/payment.dart';
import '../models/worker.dart';
import '../models/workshop.dart';

class BackupService {
  static Map<String, dynamic> buildBackupMap({
    required List<Worker> workers,
    required List<Workshop> workshops,
    required List<JournalEntry> journalEntries,
    required List<Payment> payments,
  }) {
    return {
      'app': 'daftar_al_hisab',
      'backup_version': 3,
      'exported_at': DateTime.now().toIso8601String(),
      'workers': workers.map((w) => w.toMap()).toList(),
      'workshops': workshops.map((w) => w.toMap()).toList(),
      'journal_entries': journalEntries.map((j) => j.toMap()).toList(),
      'payments': payments.map((p) => p.toMap()).toList(),
    };
  }

  /// Builds a JSON backup file containing every worker, workshop, journal
  /// entry, and payment, then opens the system share sheet so the user can
  /// save it to Drive/WhatsApp/local storage/etc.
  static Future<void> exportAndShare({
    required List<Worker> workers,
    required List<Workshop> workshops,
    required List<JournalEntry> journalEntries,
    required List<Payment> payments,
  }) async {
    final data = buildBackupMap(
      workers: workers,
      workshops: workshops,
      journalEntries: journalEntries,
      payments: payments,
    );

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/daftar_al_hisab_backup_$stamp.json');
    await file.writeAsString(jsonString);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'نسخة احتياطية من بيانات دفتر الحساب',
      ),
    );
  }

  /// Lets the user pick a previously exported JSON backup file and returns
  /// the parsed contents, or null if they cancelled the picker.
  static Future<Map<String, dynamic>?> pickAndParseBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return null;

    final path = result.files.single.path;
    if (path == null) return null;

    final content = await File(path).readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    if (json['app'] != 'daftar_al_hisab') {
      throw const FormatException('ملف النسخة الاحتياطية غير صالح');
    }
    return json;
  }
}
