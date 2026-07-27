import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_config.dart';
import '../l10n/app_localizations.dart';

class UpdateInfo {
  final int versionCode;
  final String versionName;
  final String mediafireUrl;
  final Map<AppLanguage, List<String>> changelog;

  UpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.mediafireUrl,
    required this.changelog,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    final changelogJson = json['changelog'] as Map<String, dynamic>? ?? {};
    final changelog = <AppLanguage, List<String>>{};
    for (final lang in AppLanguage.values) {
      final list = changelogJson[lang.code] as List<dynamic>?;
      if (list != null) {
        changelog[lang] = list.map((e) => e.toString()).toList();
      }
    }
    return UpdateInfo(
      versionCode: json['versionCode'] as int? ?? 0,
      versionName: json['versionName'] as String? ?? '',
      mediafireUrl:
          json['mediafireUrl'] as String? ?? AppConfig.fallbackMediaFireUrl,
      changelog: changelog,
    );
  }
}

class UpdateService {
  /// Returns update info if a newer version than the one currently
  /// installed is available, or null if up to date / the check failed
  /// (e.g. no internet, manifest not published yet).
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(Uri.parse(AppConfig.updateManifestUrl))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final info = UpdateInfo.fromJson(json);

      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber =
          int.tryParse(packageInfo.buildNumber) ?? 0;

      if (info.versionCode > currentBuildNumber) {
        return info;
      }
      return null;
    } catch (_) {
      // Silently ignore: no internet, manifest not hosted yet, malformed
      // JSON, etc. The app should never block or crash because of this.
      return null;
    }
  }
}
