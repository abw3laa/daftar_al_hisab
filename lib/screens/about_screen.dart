import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_data.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final ar = data.language == AppLanguage.ar;
    final tr = data.language == AppLanguage.tr;

    final appDescription = ar
        ? 'دفتر الحساب هو تطبيق بسيط لإدارة يوميات العمال والورشات والمشاريع، يساعد أصحاب الورش والمقاولين على تتبع أجور العمال اليومية والسلف والرصيد المستحق لكل عامل — بالإضافة إلى إمكانية استخدامه من قِبل العامل نفسه لتسجيل عمله ومتابعة رصيده.'
        : tr
            ? "Daftar Al-Hisab, işçi günlüklerini, atölyeleri ve projeleri yönetmek için basit bir uygulamadır. Atölye sahiplerinin ve yüklenicilerin günlük işçi ücretlerini, avansları ve her işçiye olan bakiyeyi takip etmesine yardımcı olur — işçilerin kendi işlerini ve bakiyelerini kaydetmesi için de kullanılabilir."
            : "Daftar Al-Hisab is a simple app for managing worker journals, workshops, and projects. It helps contractors and workshop owners track daily wages, advances, and the balance owed to each worker — and workers themselves can use it to log their own work and balance.";

    return Scaffold(
      appBar: AppBar(title: Text(data.t('about_app'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 88,
                    height: 88,
                  ),
                ),
                const SizedBox(height: 12),
                Text(data.t('app_name'),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final v = snapshot.data?.version ?? '';
                    return Text(
                      ar
                          ? 'الإصدار $v'
                          : tr
                              ? 'Sürüm $v'
                              : 'Version $v',
                      style: TextStyle(color: Colors.grey.shade600),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(appDescription, style: const TextStyle(height: 1.6)),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ar
                            ? 'تطوير: ${AppConfig.developerName}'
                            : 'Developed by: ${AppConfig.developerNameEn}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ar
                            ? 'مطوّر تطبيقات موبايل وسطح مكتب مستقل'
                            : tr
                                ? 'Bağımsız mobil ve masaüstü uygulama geliştiricisi'
                                : 'Independent mobile & desktop app developer',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chat, color: AppColors.secondary),
                  onPressed: () => launchUrl(
                    Uri.parse(
                        'https://wa.me/${AppConfig.developerContactWhatsApp}'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '© ${DateTime.now().year} ${AppConfig.developerName}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
