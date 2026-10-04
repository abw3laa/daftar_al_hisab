import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class CloudBackupScreen extends StatefulWidget {
  const CloudBackupScreen({super.key});

  @override
  State<CloudBackupScreen> createState() => _CloudBackupScreenState();
}

class _CloudBackupScreenState extends State<CloudBackupScreen> {
  bool _busy = false;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signIn(AppData data) async {
    setState(() => _busy = true);
    final ok = await data.signInToCloud();
    if (mounted) setState(() => _busy = false);
    if (!ok) {
      _snack(
        data.language == AppLanguage.ar
            ? 'تعذر تسجيل الدخول'
            : data.language == AppLanguage.tr
                ? 'Giriş yapılamadı'
                : 'Sign-in failed',
      );
    }
  }

  Future<void> _signOut(AppData data) async {
    await data.signOutFromCloud();
  }

  Future<void> _backupNow(AppData data) async {
    setState(() => _busy = true);
    final ok = await data.backupNowToCloud();
    if (mounted) setState(() => _busy = false);
    _snack(ok ? data.t('cloud_backup_success') : data.t('cloud_backup_failed'));
  }

  Future<void> _restore(AppData data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data.t('restore_from_cloud')),
        content: Text(
          data.language == AppLanguage.ar
              ? 'سيتم استبدال جميع بياناتك الحالية بمحتوى النسخة الاحتياطية على Google Drive. هل تريد المتابعة؟'
              : data.language == AppLanguage.tr
                  ? 'Mevcut tüm verileriniz Google Drive\\'daki yedeğin içeriğiyle değiştirilecek. Devam etmek istiyor musunuz?'
                  : 'All your current data will be replaced with the backup stored on Google Drive. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(data.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(data.t('confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    final ok = await data.restoreFromCloud();
    if (mounted) setState(() => _busy = false);
    _snack(ok ? data.t('restore_success') : data.t('no_cloud_backup_found'));
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    return Scaffold(
      appBar: AppBar(title: Text(data.t('cloud_backup'))),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Opacity(
          opacity: _busy ? 0.6 : 1,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (!data.isCloudSignedIn) ...[
                Icon(Icons.cloud_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  data.t('cloud_backup_desc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _signIn(data),
                  icon: const Icon(Icons.login),
                  label: Text(data.t('sign_in_google')),
                ),
              ] else ...[
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.secondary,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(data.cloudAccountEmail ?? ''),
                    subtitle: Text(data.t('connected_as')),
                    trailing: TextButton(
                      onPressed: () => _signOut(data),
                      child: Text(data.t('sign_out')),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  secondary: const Icon(Icons.sync),
                  title: Text(data.t('auto_cloud_backup')),
                  subtitle: Text(data.t('auto_cloud_backup_desc')),
                  value: data.autoCloudBackup,
                  onChanged: (v) => data.setAutoCloudBackup(v),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.history, color: AppColors.secondary),
                  title: Text(data.t('last_cloud_backup')),
                  trailing: Text(
                    data.lastCloudBackupAt == null
                        ? data.t('never')
                        : Formatters.relativeTime(data.lastCloudBackupAt),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _busy ? null : () => _backupNow(data),
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(data.t('backup_now_cloud')),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _restore(data),
                  icon: const Icon(Icons.cloud_download),
                  label: Text(data.t('restore_from_cloud')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
