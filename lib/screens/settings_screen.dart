import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_data.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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

  Future<void> _confirmWipe(BuildContext context, AppData data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
            'سيتم حذف جميع البيانات (العمال، الورشات، اليوميات، المدفوعات) نهائياً. هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await data.wipeAllData();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم حذف جميع البيانات')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppData>(
      builder: (context, data, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('الإعدادات')),
          body: ListView(
            children: [
              const _SectionHeader('إعدادات عامة'),
              ListTile(
                leading: const Icon(Icons.payments),
                title: const Text('العملة'),
                subtitle: const Text('العملة الافتراضية للمعاملات'),
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
                title: const Text('اللغة'),
                trailing: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text('العربية'), Icon(Icons.chevron_left)],
                ),
                onTap: () {},
              ),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('الوضع الداكن'),
                value: data.darkMode,
                onChanged: (v) => data.setDarkMode(v),
              ),
              const _SectionHeader('التنبيهات'),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active),
                title: const Text('تذكير يومي لتسجيل اليوميات والمصروفات'),
                value: data.dailyReminder,
                onChanged: (v) => data.setDailyReminder(v),
              ),
              const _SectionHeader('البيانات والأمان'),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('حذف جميع البيانات'),
                subtitle: const Text('مسح كافة العمال والورشات والسجلات نهائياً'),
                onTap: () => _confirmWipe(context, data),
              ),
              const _SectionHeader('حول التطبيق'),
              ListTile(
                leading: const Icon(Icons.policy),
                title: const Text('سياسة الخصوصية'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.support_agent),
                title: const Text('الدعم الفني / اتصل بنا'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => launchUrl(Uri.parse('mailto:support@example.com')),
              ),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final v = snapshot.data;
                  return ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('إصدار التطبيق'),
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
