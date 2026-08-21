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
  /// This is hosted on a small, separate PUBLIC repository
  /// (abw3laa/daftar_al_hisab_updates) rather than this repo itself, so
  /// this repository can stay private without breaking the update check
  /// (GitHub Pages requires the source repo to be public on the Free
  /// plan). Only docs/update_manifest.json needs to be kept in sync there
  /// after every release — see that repo's README.
  static const String updateManifestUrl =
      'https://abw3laa.github.io/daftar_al_hisab_updates/update_manifest.json';

  /// Direct MediaFire download page for the app, shown as a fallback / used
  /// when no manifest is reachable. Replace with your real MediaFire link
  /// after you upload a release there.
  static const String fallbackMediaFireUrl =
      'https://www.mediafire.com/file/ymyv8m9w3d1rbju/app-release.apk/file';

  /// Developer / app info shown on the About screen.
  static const String developerName = 'ياسر أبو علاء';
  static const String developerNameEn = 'Yasser Abu Alaa';
  static const String developerContactWhatsApp = supportWhatsAppNumber;
}
