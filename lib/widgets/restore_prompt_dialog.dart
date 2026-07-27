import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/app_data.dart';
import '../theme/app_theme.dart';

class RestorePromptDialog {
  static const _prefKey = 'checked_cloud_restore_prompt';

  /// Shows a "restore backup or skip" prompt the first time the app is
  /// opened with no local data yet (fresh install / reinstall). Only ever
  /// shown once — after that, restoring is still available from Settings.
  static Future<void> showIfNeeded(BuildContext context, AppData data) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefKey) == true) return;
    if (data.workers.isNotEmpty || data.workshops.isNotEmpty) {
      // There's already local data (e.g. this build was installed over an
      // existing one) — nothing to prompt for.
      await prefs.setBool(_prefKey, true);
      return;
    }

    await prefs.setBool(_prefKey, true);
    if (!context.mounted) return;

    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.cloud_download, color: AppColors.secondary),
            const SizedBox(width: 8),
            Expanded(child: Text(data.t('restore_prompt_title'))),
          ],
        ),
        content: Text(data.t('restore_prompt_desc')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'skip'),
              child: Text(data.t('skip'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'restore'),
            child: Text(data.t('restore')),
          ),
        ],
      ),
    );

    if (choice != 'restore' || !context.mounted) return;

    // Sign in, then look for a backup on that account.
    final signedIn = await data.signInToCloud();
    if (!signedIn) return;
    if (!context.mounted) return;

    final restored = await data.restoreFromCloud();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          restored ? data.t('restore_success') : data.t('no_cloud_backup_found')),
    ));
  }
}
