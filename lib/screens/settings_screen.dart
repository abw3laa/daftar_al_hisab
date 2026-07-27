import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_data.dart';
import '../services/update_service.dart';
import '../widgets/update_dialog.dart';
import 'about_screen.dart';
import 'backup_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _checkingUpdate = false;

  Future<void> _pickCurrency(BuildContext context, AppData data) async {
    const options = ['ل.ت (TRY)', 'ل.س (SYP)', 'ر.س (SAR)', 'د.إ (AED)', '\$ (USD)', 'ج.م (EGP)'];
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map((o) => ListTile(title: Text(o), onTap: () => Navigator.pop(ctx, o)))
              .toList(),
        ),
      ),
    );
    if (result != null) {
      final symbol = result.split(' ').first;
      await data.setCurrencySymbol(symbol);
    }
  }

  Future<void> _pickLanguage(BuildContext context, AppData data) async {
    final result = await showModalBottomSheet<AppLanguage>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values
              .map((lang) => ListTile(
                    title: Text(lang.nativeName),
                    trailing: data.language == lang
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () => Navigator.pop(ctx, lang),
                  ))
              .toList(),
        ),
      ),
    );
    if (result != null) {
      await data.setLanguage(result);
    }
  }

  Future<void> _pickAccountType(BuildContext context, AppData data) async {
    final result = await showModalBottomSheet<UsageMode>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.engineering),
              title: Text(data.t('account_type_contractor')),
              trailing: data.usageMode == UsageMode.contractor
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () => Navigator.pop(ctx, UsageMode.contractor),
            ),
            ListTile(
              leading: const Icon(Icons.badge),
              title: Text(data.t('account_type_worker')),
              trailing: data.usageMode == UsageMode.worker
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () => Navigator.pop(ctx, UsageMode.worker),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      await data.setUsageMode(result);
    }
  }

  Future<void> _pickReminderTime(BuildContext context, AppData data) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: data.reminderHour, minute: data.reminderMinute),
    );
    if (picked != null) {
      await data.setReminderTime(picked.hour, picked.minute);
    }
  }

  Future<void> _confirmWipe(BuildContext context, AppData data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data.t('delete')),
        content: Text(data.language == AppLanguage.ar
            ? 'سيتم حذف جميع البيانات (العمال، الورشات، اليوميات، المدفوعات) نهائياً. هل أنت متأكد؟'
            : data.language == AppLanguage.tr
                ? 'Tüm veriler (işçiler, atölyeler, günlükler, ödemeler) kalıcı olarak silinecek. Emin misiniz?'
                : 'All data (workers, workshops, journal entries, payments) will be permanently deleted. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(data.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(data.t('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await data.wipeAllData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data.language == AppLanguage.ar
              ? 'تم حذف جميع البيانات'
              : data.language == AppLanguage.tr
                  ? 'Tüm veriler silindi'
                  : 'All data has been deleted'),
        ));
      }
    }
  }

  Future<void> _checkForUpdates(AppData data) async {
    setState(() => _checkingUpdate = true);
    final update = await UpdateService.checkForUpdate();
    if (!mounted) return;
    setState(() => _checkingUpdate = false);
    if (update != null) {
      await UpdateDialog.show(context, update, data.language);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data.language == AppLanguage.ar
            ? 'التطبيق محدَّث لأحدث إصدار'
            : data.language == AppLanguage.tr
                ? 'Uygulama en güncel sürümde'
                : 'The app is up to date'),
      ));
    }
  }

  void _openSupport() {
    launchUrl(
      Uri.parse('https://wa.me/${AppConfig.supportWhatsAppNumber}'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppData>(
      builder: (context, data, _) {
        return Scaffold(
          appBar: AppBar(title: Text(data.t('drawer_settings'))),
          body: ListView(
            children: [
              _SectionHeader(data.t('general_settings')),
              ListTile(
                leading: const Icon(Icons.payments),
                title: Text(data.t('currency')),
                subtitle: Text(data.t('currency_desc')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(data.currencySymbol),
                    const Icon(Icons.chevron_left),
                  ],
                ),
                onTap: () => _pickCurrency(context, data),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(data.t('language')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(data.language.nativeName),
                    const Icon(Icons.chevron_left),
                  ],
                ),
                onTap: () => _pickLanguage(context, data),
              ),
              ListTile(
                leading: const Icon(Icons.switch_account),
                title: Text(data.t('account_type')),
                subtitle: Text(data.usageMode == UsageMode.contractor
                    ? data.t('account_type_contractor')
                    : data.t('account_type_worker')),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => _pickAccountType(context, data),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: Text(data.t('dark_mode')),
                value: data.darkMode,
                onChanged: (v) => data.setDarkMode(v),
              ),
              _SectionHeader(data.t('notifications')),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active),
                title: Text(data.t('daily_reminder')),
                value: data.dailyReminder,
                onChanged: (v) => data.setDailyReminder(v),
              ),
              if (data.dailyReminder)
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(data.t('reminder_time')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(TimeOfDay(
                              hour: data.reminderHour,
                              minute: data.reminderMinute)
                          .format(context)),
                      const Icon(Icons.chevron_left),
                    ],
                  ),
                  onTap: () => _pickReminderTime(context, data),
                ),
              _SectionHeader(data.t('data_security')),
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: Text(data.t('drawer_backup')),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BackupScreen())),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(data.t('delete_all_data')),
                subtitle: Text(data.t('delete_all_data_desc')),
                onTap: () => _confirmWipe(context, data),
              ),
              _SectionHeader(data.t('about_app')),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(data.t('about_app')),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AboutScreen())),
              ),
              ListTile(
                leading: const Icon(Icons.policy),
                title: Text(data.t('privacy_policy')),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen())),
              ),
              ListTile(
                leading: const Icon(Icons.support_agent),
                title: Text(data.t('support')),
                trailing: const Icon(Icons.chevron_left),
                onTap: _openSupport,
              ),
              ListTile(
                leading: _checkingUpdate
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.system_update),
                title: Text(data.t('check_for_updates')),
                onTap: _checkingUpdate ? null : () => _checkForUpdates(data),
              ),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final v = snapshot.data;
                  return ListTile(
                    leading: const Icon(Icons.info),
                    title: Text(data.t('app_version_label')),
                    trailing: Text(v == null ? '' : 'v${v.version} (${v.buildNumber})'),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
