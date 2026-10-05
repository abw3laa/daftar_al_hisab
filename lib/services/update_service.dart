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
  /// Compares semantic version names first and build numbers second.
  ///
  /// The build number is used as a tie-breaker so an older installed build
  /// such as 1.5.0+2006 can correctly detect 1.6.1+2007 even when historical
  /// releases used a different build-numbering scheme.
  static bool _isNewerVersion(
    String availableVersion,
    int availableBuild,
    String currentVersion,
    int currentBuild,
  ) {
    List<int> parseVersion(String value) {
      final match = RegExp(r'^(\d+)(?:\.(\d+))?(?:\.(\d+))?')
          .firstMatch(value.trim());
      if (match == null) return const [0, 0, 0];
      return [
        int.tryParse(match.group(1)!) ?? 0,
        int.tryParse(match.group(2) ?? '0') ?? 0,
        int.tryParse(match.group(3) ?? '0') ?? 0,
      ];
    }

    final available = parseVersion(availableVersion);
    final current = parseVersion(currentVersion);

    for (var i = 0; i < 3; i++) {
      if (available[i] != current[i]) {
        return available[i] > current[i];
      }
    }

    return availableBuild > currentBuild;
  }

  /// Returns update info if a newer version than the one currently
  /// installed is available, or null if up to date / the check failed.
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

      if (_isNewerVersion(
        info.versionName,
        info.versionCode,
        packageInfo.version,
        currentBuildNumber,
      )) {
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
