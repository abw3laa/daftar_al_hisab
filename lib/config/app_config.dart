/// Central place for values that are specific to this deployment and that
/// you (the developer) should fill in / keep up to date after every release.
class AppConfig {
  /// WhatsApp number used for the "Support / Contact us" settings entry.
  /// Format: country code + number, no plus sign, no spaces/dashes.
  static const String supportWhatsAppNumber = '905354883886';

  /// URL of a small JSON file YOU host (e.g. on GitHub Pages, exactly like
  /// the "حالاتي" project's update manifest) describing the latest release.
  static const String updateManifestUrl =
      'https://abw3laa.github.io/daftar_al_hisab_updates/update_manifest.json';

  /// Direct MediaFire download page for the app, shown as a fallback / used
  /// when no manifest is reachable.
  static const String fallbackMediaFireUrl =
      'https://www.mediafire.com/file/xvswvowy7r2dr8l/daftar+al+hisab.apk/file';

  /// Developer / app info shown on the About screen.
  static const String developerName = 'ياسر أبو علاء';
  static const String developerNameEn = 'Yasser Abu Alaa';
  static const String developerContactWhatsApp = supportWhatsAppNumber;
}
