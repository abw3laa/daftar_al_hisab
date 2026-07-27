import '../l10n/app_localizations.dart';

/// Bump the key whenever you release a new version, and add the bullet
/// points describing what changed. Shown once to the user the first time
/// they open the app after updating (see WhatsNewService).
class Changelog {
  static const Map<String, Map<AppLanguage, List<String>>> entries = {
    '1.2.0': {
      AppLanguage.ar: [
        'نسخ احتياطي سحابي على Google Drive مع نسخ تلقائي بعد كل تعديل',
        'شاشة استعادة نسخة احتياطية عند أول فتح للتطبيق',
        'توقيع دائم للتطبيق لضمان استمرار عمل تسجيل الدخول بـ Google بين التحديثات',
      ],
      AppLanguage.en: [
        'Cloud backup to Google Drive with automatic sync after every change',
        'Restore-backup prompt on first launch',
        'Permanent app signing so Google Sign-In keeps working across updates',
      ],
      AppLanguage.tr: [
        'Her değişiklikten sonra otomatik senkronizasyonla Google Drive\'a bulut yedekleme',
        'İlk açılışta yedek geri yükleme istemi',
        'Google ile Girişin güncellemeler arasında çalışmaya devam etmesi için kalıcı uygulama imzalama',
      ],
    },
    '1.1.0': {
      AppLanguage.ar: [
        'دعم لغات جديدة: الإنجليزية والتركية بجانب العربية',
        'إمكانية استخدام التطبيق للعامل نفسه لتسجيل عمله ومتابعة رصيده',
        'ميزة النسخ الاحتياطي واستعادة البيانات',
        'إمكانية تعديل وحذف بيانات العمال والورشات',
        'إصلاح ظهور النص العربي في ملفات PDF المُصدَّرة',
        'تفعيل التنبيهات اليومية بشكل صحيح',
        'شاشة "حول التطبيق" وسياسة خصوصية حقيقية',
        'التحقق التلقائي من التحديثات الجديدة',
      ],
      AppLanguage.en: [
        'New languages: English and Turkish alongside Arabic',
        'Workers can now use the app themselves to log their own work and balance',
        'Backup and restore your data',
        'Edit and delete workers and workshops',
        'Fixed Arabic text rendering in exported PDFs',
        'Daily reminder notifications now work correctly',
        '"About" screen and a real privacy policy',
        'Automatic update checking',
      ],
      AppLanguage.tr: [
        'Yeni diller: Arapça yanında İngilizce ve Türkçe',
        'İşçiler artık kendi işlerini ve bakiyelerini kaydedebilir',
        'Verilerinizi yedekleyin ve geri yükleyin',
        'İşçileri ve atölyeleri düzenleyin/silin',
        'PDF dışa aktarımında Arapça metin sorunu düzeltildi',
        'Günlük hatırlatma bildirimleri artık düzgün çalışıyor',
        'Gerçek bir "Hakkında" ve gizlilik politikası sayfası',
        'Otomatik güncelleme kontrolü',
      ],
    },
  };

  static String get latestVersion => entries.keys.last;
}
