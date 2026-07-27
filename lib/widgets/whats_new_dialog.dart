import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/changelog.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class WhatsNewDialog {
  static const _prefKey = 'last_seen_changelog_version';

  /// Shows the "What's new" dialog once per version, the first time the
  /// app is opened after an update. Safe to call on every app start.
  static Future<void> showIfNeeded(
      BuildContext context, AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getString(_prefKey);
    final latest = Changelog.latestVersion;

    if (lastSeen == latest) return;

    final bullets = Changelog.entries[latest]?[language] ??
        Changelog.entries[latest]?[AppLanguage.ar] ??
        [];

    await prefs.setString(_prefKey, latest);

    if (!context.mounted || bullets.isEmpty) return;

    final title = language == AppLanguage.ar
        ? 'ما الجديد في الإصدار $latest'
        : language == AppLanguage.tr
            ? '$latest sürümünde yenilikler'
            : "What's new in $latest";
    final closeLabel = language == AppLanguage.ar
        ? 'حسناً'
        : language == AppLanguage.tr
            ? 'Tamam'
            : 'Got it';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.celebration, color: AppColors.secondary),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: bullets
                .map((b) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle,
                              size: 18, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(b)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(closeLabel),
          ),
        ],
      ),
    );
  }
}
