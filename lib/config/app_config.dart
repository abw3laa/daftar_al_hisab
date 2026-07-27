/// Central place for values that are specific to this deployment and that
/// you (the developer) should fill in / keep up to date after every release.
class AppConfig {
  /// WhatsApp number used for the "Support / Contact us" settings entry.
  /// Format: country code + number, no plus sign, no spaces/dashes.
  static const String supportWhatsAppNumber = '905354883886';

  /// URL of a small JSON file YOU host (e.g. on GitHub Pages, exactly like
  /// the "حالاتي" project's update manifest) describing the latest release.
  /// Example content:
  /// {
  ///   "versionCode": 2,
  ///   "versionName": "1.1.0",
  ///   "mediafireUrl": "https://www.mediafire.com/file/xxxxxxxx/daftar_al_hisab.apk/file",
  ///   "changelog": {
  ///     "ar": ["إصلاح مشكلة كذا", "ميزة جديدة كذا"],
  ///     "en": ["Fixed something", "New feature"],
  ///     "tr": ["Bir şey düzeltildi", "Yeni özellik"]
  ///   }
  /// }
  ///
  /// Update this URL once you publish update_manifest.json somewhere public
  /// (see update_manifest.example.json in the repo root for a starting
  /// point). Until you do, the in-app update check will simply fail
  /// silently and the app will behave as if it's always up to date.
  static const String updateManifestUrl =
      'https://abw3laa.github.io/daftar_al_hisab/update_manifest.json';

  /// Direct MediaFire download page for the app, shown as a fallback / used
  /// when no manifest is reachable. Replace with your real MediaFire link
  /// after you upload a release there.
  static const String fallbackMediaFireUrl =
      'https://www.mediafire.com/file/REPLACE_ME/daftar_al_hisab.apk/file';

  /// Developer / app info shown on the About screen.
  static const String developerName = 'ياسر أبو علاء';
  static const String developerNameEn = 'Yasser Abu Alaa';
  static const String developerContactWhatsApp = supportWhatsAppNumber;
}
