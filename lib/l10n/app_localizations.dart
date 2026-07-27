import 'package:flutter/material.dart';

enum AppLanguage { ar, en, tr }

extension AppLanguageX on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.ar:
        return 'ar';
      case AppLanguage.en:
        return 'en';
      case AppLanguage.tr:
        return 'tr';
    }
  }

  String get nativeName {
    switch (this) {
      case AppLanguage.ar:
        return 'العربية';
      case AppLanguage.en:
        return 'English';
      case AppLanguage.tr:
        return 'Türkçe';
    }
  }

  TextDirection get textDirection =>
      this == AppLanguage.ar ? TextDirection.rtl : TextDirection.ltr;

  static AppLanguage fromCode(String code) {
    switch (code) {
      case 'en':
        return AppLanguage.en;
      case 'tr':
        return AppLanguage.tr;
      default:
        return AppLanguage.ar;
    }
  }
}

/// Central translation dictionary. Keys are looked up per current language,
/// falling back to Arabic if a translation is missing.
class AppLocalizations {
  static const Map<String, Map<AppLanguage, String>> _strings = {
    'app_name': {
      AppLanguage.ar: 'دفتر الحساب',
      AppLanguage.en: 'Daftar Al-Hisab',
      AppLanguage.tr: 'Daftar Al-Hisab',
    },
    // Navigation
    'nav_journal': {
      AppLanguage.ar: 'اليوميات',
      AppLanguage.en: 'Journal',
      AppLanguage.tr: 'Günlük',
    },
    'nav_workshops': {
      AppLanguage.ar: 'الورشات',
      AppLanguage.en: 'Workshops',
      AppLanguage.tr: 'Atölyeler',
    },
    'nav_workers': {
      AppLanguage.ar: 'العمال',
      AppLanguage.en: 'Workers',
      AppLanguage.tr: 'İşçiler',
    },
    'nav_my_journal': {
      AppLanguage.ar: 'يومياتي',
      AppLanguage.en: 'My Journal',
      AppLanguage.tr: 'Günlüğüm',
    },
    // Drawer
    'drawer_reports': {
      AppLanguage.ar: 'التقارير',
      AppLanguage.en: 'Reports',
      AppLanguage.tr: 'Raporlar',
    },
    'drawer_settings': {
      AppLanguage.ar: 'الإعدادات',
      AppLanguage.en: 'Settings',
      AppLanguage.tr: 'Ayarlar',
    },
    'drawer_about': {
      AppLanguage.ar: 'حول التطبيق',
      AppLanguage.en: 'About',
      AppLanguage.tr: 'Hakkında',
    },
    'drawer_backup': {
      AppLanguage.ar: 'النسخ الاحتياطي',
      AppLanguage.en: 'Backup',
      AppLanguage.tr: 'Yedekleme',
    },
    'app_version': {
      AppLanguage.ar: 'دفتر الحساب - إصدار',
      AppLanguage.en: 'Daftar Al-Hisab - version',
      AppLanguage.tr: 'Daftar Al-Hisab - sürüm',
    },
    // Common actions
    'save': {
      AppLanguage.ar: 'حفظ',
      AppLanguage.en: 'Save',
      AppLanguage.tr: 'Kaydet',
    },
    'cancel': {
      AppLanguage.ar: 'إلغاء',
      AppLanguage.en: 'Cancel',
      AppLanguage.tr: 'İptal',
    },
    'add': {
      AppLanguage.ar: 'إضافة',
      AppLanguage.en: 'Add',
      AppLanguage.tr: 'Ekle',
    },
    'edit': {
      AppLanguage.ar: 'تعديل',
      AppLanguage.en: 'Edit',
      AppLanguage.tr: 'Düzenle',
    },
    'delete': {
      AppLanguage.ar: 'حذف',
      AppLanguage.en: 'Delete',
      AppLanguage.tr: 'Sil',
    },
    'confirm': {
      AppLanguage.ar: 'تأكيد',
      AppLanguage.en: 'Confirm',
      AppLanguage.tr: 'Onayla',
    },
    'search': {
      AppLanguage.ar: 'بحث',
      AppLanguage.en: 'Search',
      AppLanguage.tr: 'Ara',
    },
    'share': {
      AppLanguage.ar: 'مشاركة',
      AppLanguage.en: 'Share',
      AppLanguage.tr: 'Paylaş',
    },
    'export_pdf': {
      AppLanguage.ar: 'تصدير PDF',
      AppLanguage.en: 'Export PDF',
      AppLanguage.tr: 'PDF olarak dışa aktar',
    },
    'name': {
      AppLanguage.ar: 'الاسم',
      AppLanguage.en: 'Name',
      AppLanguage.tr: 'İsim',
    },
    'notes_optional': {
      AppLanguage.ar: 'ملاحظات (اختياري)',
      AppLanguage.en: 'Notes (optional)',
      AppLanguage.tr: 'Notlar (isteğe bağlı)',
    },
    'date': {
      AppLanguage.ar: 'التاريخ',
      AppLanguage.en: 'Date',
      AppLanguage.tr: 'Tarih',
    },
    // Dashboard
    'today_workers': {
      AppLanguage.ar: 'عمال اليوم',
      AppLanguage.en: "Today's workers",
      AppLanguage.tr: 'Bugünün işçileri',
    },
    'no_journal_today': {
      AppLanguage.ar: 'لا توجد يوميات مسجلة في هذا اليوم',
      AppLanguage.en: 'No journal entries recorded for this day',
      AppLanguage.tr: 'Bu gün için kayıtlı günlük yok',
    },
    // Add journal
    'record_journal': {
      AppLanguage.ar: 'تسجيل يومية',
      AppLanguage.en: 'Record work day',
      AppLanguage.tr: 'Günlük kaydet',
    },
    'worker_name': {
      AppLanguage.ar: 'اسم العامل',
      AppLanguage.en: 'Worker name',
      AppLanguage.tr: 'İşçi adı',
    },
    'workshop_name': {
      AppLanguage.ar: 'اسم الورشة / موقع العمل',
      AppLanguage.en: 'Workshop / site name',
      AppLanguage.tr: 'Atölye / şantiye adı',
    },
    'daily_wage': {
      AppLanguage.ar: 'أجر اليوم / اليومية',
      AppLanguage.en: 'Daily wage',
      AppLanguage.tr: 'Günlük ücret',
    },
    'worker_present': {
      AppLanguage.ar: 'العامل حاضر / تم إنجاز العمل',
      AppLanguage.en: 'Worker present / work completed',
      AppLanguage.tr: 'İşçi mevcut / iş tamamlandı',
    },
    'save_and_record': {
      AppLanguage.ar: 'حفظ وتسجيل',
      AppLanguage.en: 'Save entry',
      AppLanguage.tr: 'Kaydet',
    },
    // Workshops
    'workshops_overview': {
      AppLanguage.ar: 'نظرة عامة على جميع المواقع النشطة',
      AppLanguage.en: 'An overview of all active sites',
      AppLanguage.tr: 'Tüm aktif sahalara genel bakış',
    },
    'no_workshops_yet': {
      AppLanguage.ar: 'لا توجد ورشات بعد',
      AppLanguage.en: 'No workshops yet',
      AppLanguage.tr: 'Henüz atölye yok',
    },
    'new_project': {
      AppLanguage.ar: 'مشروع جديد',
      AppLanguage.en: 'New project',
      AppLanguage.tr: 'Yeni proje',
    },
    'new_workshop_title': {
      AppLanguage.ar: 'مشروع / ورشة جديدة',
      AppLanguage.en: 'New project / workshop',
      AppLanguage.tr: 'Yeni proje / atölye',
    },
    'location': {
      AppLanguage.ar: 'الموقع',
      AppLanguage.en: 'Location',
      AppLanguage.tr: 'Konum',
    },
    'total_work_days': {
      AppLanguage.ar: 'إجمالي أيام العمل',
      AppLanguage.en: 'Total work days',
      AppLanguage.tr: 'Toplam çalışma günü',
    },
    'total_cost': {
      AppLanguage.ar: 'التكلفة الإجمالية',
      AppLanguage.en: 'Total cost',
      AppLanguage.tr: 'Toplam maliyet',
    },
    'last_activity': {
      AppLanguage.ar: 'آخر نشاط',
      AppLanguage.en: 'Last activity',
      AppLanguage.tr: 'Son etkinlik',
    },
    'workers_in_workshop': {
      AppLanguage.ar: 'العمال في هذه الورشة',
      AppLanguage.en: 'Workers in this workshop',
      AppLanguage.tr: 'Bu atölyedeki işçiler',
    },
    'journal_log': {
      AppLanguage.ar: 'سجل اليوميات',
      AppLanguage.en: 'Journal log',
      AppLanguage.tr: 'Günlük kaydı',
    },
    // Workers
    'search_worker': {
      AppLanguage.ar: 'بحث عن عامل',
      AppLanguage.en: 'Search a worker',
      AppLanguage.tr: 'İşçi ara',
    },
    'no_workers_yet': {
      AppLanguage.ar: 'لا يوجد عمال بعد',
      AppLanguage.en: 'No workers yet',
      AppLanguage.tr: 'Henüz işçi yok',
    },
    'new_worker': {
      AppLanguage.ar: 'عامل جديد',
      AppLanguage.en: 'New worker',
      AppLanguage.tr: 'Yeni işçi',
    },
    'profession': {
      AppLanguage.ar: 'المهنة',
      AppLanguage.en: 'Profession',
      AppLanguage.tr: 'Meslek',
    },
    'phone_optional': {
      AppLanguage.ar: 'رقم الهاتف (اختياري)',
      AppLanguage.en: 'Phone number (optional)',
      AppLanguage.tr: 'Telefon numarası (isteğe bağlı)',
    },
    // Worker profile
    'balance_due': {
      AppLanguage.ar: 'الرصيد المستحق',
      AppLanguage.en: 'Balance due',
      AppLanguage.tr: 'Bakiye',
    },
    'balance_due_to_worker': {
      AppLanguage.ar: 'الرصيد المستحق للعامل',
      AppLanguage.en: 'Balance due to worker',
      AppLanguage.tr: 'İşçiye borç bakiyesi',
    },
    'total_journal': {
      AppLanguage.ar: 'إجمالي اليوميات',
      AppLanguage.en: 'Total wages earned',
      AppLanguage.tr: 'Toplam kazanılan ücret',
    },
    'total_payments': {
      AppLanguage.ar: 'إجمالي السلف',
      AppLanguage.en: 'Total payments',
      AppLanguage.tr: 'Toplam ödemeler',
    },
    'transactions_log': {
      AppLanguage.ar: 'سجل الحركات',
      AppLanguage.en: 'Transaction history',
      AppLanguage.tr: 'İşlem geçmişi',
    },
    'no_transactions_yet': {
      AppLanguage.ar: 'لا توجد حركات مسجلة بعد',
      AppLanguage.en: 'No transactions recorded yet',
      AppLanguage.tr: 'Henüz işlem yok',
    },
    'payments': {
      AppLanguage.ar: 'المدفوعات',
      AppLanguage.en: 'Payments',
      AppLanguage.tr: 'Ödemeler',
    },
    // Payments
    'new_payment': {
      AppLanguage.ar: 'دفعة جديدة',
      AppLanguage.en: 'New payment',
      AppLanguage.tr: 'Yeni ödeme',
    },
    'payment_type': {
      AppLanguage.ar: 'نوع الدفعة',
      AppLanguage.en: 'Payment type',
      AppLanguage.tr: 'Ödeme türü',
    },
    'amount': {
      AppLanguage.ar: 'المبلغ',
      AppLanguage.en: 'Amount',
      AppLanguage.tr: 'Tutar',
    },
    'payments_log': {
      AppLanguage.ar: 'سجل المدفوعات',
      AppLanguage.en: 'Payments log',
      AppLanguage.tr: 'Ödeme kaydı',
    },
    'no_payments_yet': {
      AppLanguage.ar: 'لا توجد مدفوعات مسجلة بعد',
      AppLanguage.en: 'No payments recorded yet',
      AppLanguage.tr: 'Henüz ödeme yok',
    },
    // Settings
    'general_settings': {
      AppLanguage.ar: 'إعدادات عامة',
      AppLanguage.en: 'General settings',
      AppLanguage.tr: 'Genel ayarlar',
    },
    'currency': {
      AppLanguage.ar: 'العملة',
      AppLanguage.en: 'Currency',
      AppLanguage.tr: 'Para birimi',
    },
    'currency_desc': {
      AppLanguage.ar: 'العملة الافتراضية للمعاملات',
      AppLanguage.en: 'Default currency for transactions',
      AppLanguage.tr: 'İşlemler için varsayılan para birimi',
    },
    'language': {
      AppLanguage.ar: 'اللغة',
      AppLanguage.en: 'Language',
      AppLanguage.tr: 'Dil',
    },
    'dark_mode': {
      AppLanguage.ar: 'الوضع الداكن',
      AppLanguage.en: 'Dark mode',
      AppLanguage.tr: 'Karanlık mod',
    },
    'account_type': {
      AppLanguage.ar: 'نوع الحساب',
      AppLanguage.en: 'Account type',
      AppLanguage.tr: 'Hesap türü',
    },
    'account_type_contractor': {
      AppLanguage.ar: 'صاحب عمل / متعهد',
      AppLanguage.en: 'Contractor / employer',
      AppLanguage.tr: 'Yüklenici / işveren',
    },
    'account_type_worker': {
      AppLanguage.ar: 'عامل',
      AppLanguage.en: 'Worker',
      AppLanguage.tr: 'İşçi',
    },
    'notifications': {
      AppLanguage.ar: 'التنبيهات',
      AppLanguage.en: 'Notifications',
      AppLanguage.tr: 'Bildirimler',
    },
    'daily_reminder': {
      AppLanguage.ar: 'تذكير يومي لتسجيل اليوميات والمصروفات',
      AppLanguage.en: 'Daily reminder to log work and expenses',
      AppLanguage.tr: 'Günlük iş ve masraf hatırlatıcısı',
    },
    'reminder_time': {
      AppLanguage.ar: 'وقت التذكير',
      AppLanguage.en: 'Reminder time',
      AppLanguage.tr: 'Hatırlatma saati',
    },
    'data_security': {
      AppLanguage.ar: 'البيانات والأمان',
      AppLanguage.en: 'Data & Security',
      AppLanguage.tr: 'Veri ve Güvenlik',
    },
    'backup_export': {
      AppLanguage.ar: 'تصدير نسخة احتياطية',
      AppLanguage.en: 'Export backup',
      AppLanguage.tr: 'Yedeği dışa aktar',
    },
    'backup_export_desc': {
      AppLanguage.ar: 'حفظ نسخة من جميع بياناتك في ملف يمكنك مشاركته',
      AppLanguage.en: 'Save a copy of all your data to a shareable file',
      AppLanguage.tr: 'Tüm verilerinizin bir kopyasını paylaşılabilir bir dosyaya kaydedin',
    },
    'backup_import': {
      AppLanguage.ar: 'استيراد نسخة احتياطية',
      AppLanguage.en: 'Import backup',
      AppLanguage.tr: 'Yedeği içe aktar',
    },
    'backup_import_desc': {
      AppLanguage.ar: 'استعادة بياناتك من ملف نسخة احتياطية',
      AppLanguage.en: 'Restore your data from a backup file',
      AppLanguage.tr: 'Verilerinizi bir yedek dosyasından geri yükleyin',
    },
    'delete_all_data': {
      AppLanguage.ar: 'حذف جميع البيانات',
      AppLanguage.en: 'Delete all data',
      AppLanguage.tr: 'Tüm verileri sil',
    },
    'delete_all_data_desc': {
      AppLanguage.ar: 'مسح كافة العمال والورشات والسجلات نهائياً',
      AppLanguage.en: 'Permanently erase all workers, workshops, and records',
      AppLanguage.tr: 'Tüm işçileri, atölyeleri ve kayıtları kalıcı olarak sil',
    },
    'about_app': {
      AppLanguage.ar: 'حول التطبيق',
      AppLanguage.en: 'About the app',
      AppLanguage.tr: 'Uygulama hakkında',
    },
    'privacy_policy': {
      AppLanguage.ar: 'سياسة الخصوصية',
      AppLanguage.en: 'Privacy Policy',
      AppLanguage.tr: 'Gizlilik Politikası',
    },
    'support': {
      AppLanguage.ar: 'الدعم الفني / اتصل بنا',
      AppLanguage.en: 'Support / Contact us',
      AppLanguage.tr: 'Destek / Bize Ulaşın',
    },
    'check_for_updates': {
      AppLanguage.ar: 'التحقق من وجود تحديثات',
      AppLanguage.en: 'Check for updates',
      AppLanguage.tr: 'Güncellemeleri kontrol et',
    },
    'app_version_label': {
      AppLanguage.ar: 'إصدار التطبيق',
      AppLanguage.en: 'App version',
      AppLanguage.tr: 'Uygulama sürümü',
    },
    // Reports
    'total_owed_to_workers': {
      AppLanguage.ar: 'إجمالي المستحق للعمال',
      AppLanguage.en: 'Total owed to workers',
      AppLanguage.tr: 'İşçilere toplam borç',
    },
    'wages_this_month': {
      AppLanguage.ar: 'أجور هذا الشهر',
      AppLanguage.en: "This month's wages",
      AppLanguage.tr: 'Bu ayın ücretleri',
    },
    'cost_by_workshop': {
      AppLanguage.ar: 'التكلفة حسب الورشة',
      AppLanguage.en: 'Cost by workshop',
      AppLanguage.tr: 'Atölyeye göre maliyet',
    },
    'not_enough_data': {
      AppLanguage.ar: 'لا توجد بيانات كافية بعد',
      AppLanguage.en: 'Not enough data yet',
      AppLanguage.tr: 'Henüz yeterli veri yok',
    },
    'top_owed_workers': {
      AppLanguage.ar: 'العمال الأكثر استحقاقاً',
      AppLanguage.en: 'Highest balances owed',
      AppLanguage.tr: 'En yüksek bakiyeli işçiler',
    },
  };

  static String t(String key, AppLanguage lang) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[lang] ?? entry[AppLanguage.ar] ?? key;
  }
}
