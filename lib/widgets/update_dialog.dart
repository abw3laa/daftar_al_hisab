import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';

class UpdateDialog {
  static Future<void> show(
      BuildContext context, UpdateInfo info, AppLanguage language) async {
    if (!context.mounted) return;
    final bullets =
        info.changelog[language] ?? info.changelog[AppLanguage.ar] ?? [];

    final title = language == AppLanguage.ar
        ? 'يتوفر تحديث جديد'
        : language == AppLanguage.tr
            ? 'Yeni güncelleme mevcut'
            : 'A new update is available';
    final subtitle = language == AppLanguage.ar
        ? 'الإصدار ${info.versionName} متاح الآن للتحميل من MediaFire'
        : language == AppLanguage.tr
            ? '${info.versionName} sürümü MediaFire üzerinden indirilebilir'
            : 'Version ${info.versionName} is now available to download from MediaFire';
    final downloadLabel = language == AppLanguage.ar
        ? 'تحميل التحديث'
        : language == AppLanguage.tr
            ? 'Güncellemeyi indir'
            : 'Download update';
    final laterLabel = language == AppLanguage.ar
        ? 'لاحقاً'
        : language == AppLanguage.tr
            ? 'Daha sonra'
            : 'Later';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update, color: AppColors.secondary),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            if (bullets.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...bullets.map((b) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(child: Text(b)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(laterLabel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              launchUrl(Uri.parse(info.mediafireUrl),
                  mode: LaunchMode.externalApplication);
            },
            child: Text(downloadLabel),
          ),
        ],
      ),
    );
  }
}
