import '../l10n/app_localizations.dart';

/// Bump the key whenever you release a new version, and add the bullet
/// points describing what changed. Shown once to the user the first time
/// they open the app after updating (see WhatsNewService).
class Changelog {
  static const Map<String, Map<AppLanguage, List<String>>> entries = {
    '1.5.0': {
      AppLanguage.ar: [
        'تحسينات على شاشات المحاسبة وكشف حساب العامل',
        'إضافة دورة الرواتب الشهرية وإغلاق وفتح الفترة المحاسبية',
        'تحسين سجل الحركات والحسابات والتقارير',
        'تحسينات في النسخ الاحتياطي والاستعادة والمزامنة السحابية',
        'تحسينات عامة في التصميم وتجربة الاستخدام والاستقرار',
      ],
      AppLanguage.en: [
        'Improved accounting screens and worker statements',
        'Monthly payroll periods with period closing and reopening',
        'Improved ledger, calculations, and reports',
        'Improved backup, restore, and cloud synchronization',
        'General UI, UX, and stability improvements',
      ],
      AppLanguage.tr: [
        'Muhasebe ekranları ve işçi ekstreleri geliştirildi',
        'Aylık bordro dönemleri ve dönem kapatma/açma desteği',
        'Hesap hareketleri, hesaplamalar ve raporlar geliştirildi',
        'Yedekleme, geri yükleme ve bulut senkronizasyonu iyileştirildi',
        'Genel arayüz, kullanıcı deneyimi ve kararlılık iyileştirmeleri',
      ],
    },
    '1.3.0': {
      AppLanguage.ar: [
        'واجهة تقويم شهرية لعرض أيام العمل والحالة والملاحظات بسرعة',
        'تعديل وحذف اليوميات والمدفوعات مع تأكيد قبل الحذف',
        'حساب أدق يدعم نصف اليوم والساعات الإضافية والخصومات',
        'كشوفات PDF بخط عربي مضمن وشعار التطبيق',
        'تحسين الثيم والواجهات وتجربة الاستخدام',
      ],
      AppLanguage.en: [
        'Monthly calendar for work days, status, and notes at a glance',
        'Edit and delete journal entries and payments with confirmation',
        'More accurate calculations with half-days, overtime, and deductions',
        'PDF statements with an embedded Arabic font and app logo',
        'Refreshed theme and improved user experience',
      ],
      AppLanguage.tr: [
        'Çalışma günlerini, durumu ve notları gösteren aylık takvim',
        'Onaylı günlük ve ödeme düzenleme/silme işlemleri',
        'Yarım gün, fazla mesai ve kesintilerle daha doğru hesaplama',
        'Gömülü Arapça yazı tipi ve uygulama logosuyla PDF ekstreleri',
        'Yenilenen tema ve geliştirilmiş kullanıcı deneyimi',
      ],
    },
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

  static String get latestVersion => entries.keys.reduce((a, b) {
        final left = a.split('.').map((part) => int.tryParse(part) ?? 0).toList();
        final right = b.split('.').map((part) => int.tryParse(part) ?? 0).toList();
        for (var i = 0; i < 3; i++) {
          final comparison = (left.length > i ? left[i] : 0)
              .compareTo(right.length > i ? right[i] : 0);
          if (comparison != 0) return comparison > 0 ? a : b;
        }
        return a;
      });
}
