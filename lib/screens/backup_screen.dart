import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_data.dart';
import '../services/backup_service.dart';
import '../theme/app_theme.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;

  Future<void> _export(AppData data) async {
    setState(() => _busy = true);
    try {
      await BackupService.exportAndShare(
        workers: data.workers,
        workshops: data.workshops,
        journalEntries: data.journalEntries,
        payments: data.payments,
        payrollPeriods: data.payrollPeriods,
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import(AppData data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data.t('backup_import')),
        content: Text(data.language == AppLanguage.ar
            ? 'سيتم استبدال جميع بياناتك الحالية بمحتوى ملف النسخة الاحتياطية. هل تريد المتابعة؟'
            : data.language == AppLanguage.tr
                ? 'Mevcut tüm verileriniz yedek dosyasının içeriğiyle değiştirilecek. Devam etmek istiyor musunuz?'
                : 'All your current data will be replaced with the backup file contents. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(data.t('cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(data.t('confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final json = await BackupService.pickAndParseBackupFile();
      if (json != null) {
        await data.importBackup(json);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data.language == AppLanguage.ar
                ? 'تم استعادة البيانات بنجاح'
                : data.language == AppLanguage.tr
                    ? 'Veriler başarıyla geri yüklendi'
                    : 'Data restored successfully'),
          ));
        }
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    return Scaffold(
      appBar: AppBar(title: Text(data.t('drawer_backup'))),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Opacity(
          opacity: _busy ? 0.6 : 1,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.upload_file,
                      color: AppColors.secondary),
                  title: Text(data.t('backup_export')),
                  subtitle: Text(data.t('backup_export_desc')),
                  trailing: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.chevron_left),
                  onTap: () => _export(data),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading:
                      const Icon(Icons.download_outlined, color: Colors.orange),
                  title: Text(data.t('backup_import')),
                  subtitle: Text(data.t('backup_import_desc')),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => _import(data),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                data.language == AppLanguage.ar
                    ? 'نصيحة: يُفضّل أخذ نسخة احتياطية بشكل دوري، خصوصاً قبل تحديث التطبيق أو تغيير الهاتف.'
                    : data.language == AppLanguage.tr
                        ? 'İpucu: Özellikle uygulamayı güncellemeden veya telefon değiştirmeden önce düzenli olarak yedek almanız önerilir.'
                        : 'Tip: it\'s a good idea to back up regularly, especially before updating the app or switching phones.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
