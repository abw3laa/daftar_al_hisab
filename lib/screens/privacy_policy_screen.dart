import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_data.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final content = switch (data.language) {
      AppLanguage.ar => _arabicContent,
      AppLanguage.en => _englishContent,
      AppLanguage.tr => _turkishContent,
    };

    return Scaffold(
      appBar: AppBar(title: Text(data.t('privacy_policy'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(content, style: const TextStyle(height: 1.8, fontSize: 14)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

const _arabicContent = '''
سياسة الخصوصية - دفتر الحساب

آخر تحديث: 2026

خصوصيتك مهمة بالنسبة لنا. هذه السياسة تشرح بوضوح وبدقة كيف يتعامل تطبيق "دفتر الحساب" مع بياناتك.

1. التخزين المحلي فقط
جميع البيانات التي تُدخلها في التطبيق (أسماء العمال، الورشات، اليوميات، المدفوعات، الإعدادات) تُخزَّن حصرياً على جهازك في قاعدة بيانات محلية (SQLite). التطبيق لا يملك خادماً خاصاً يستقبل أو يخزّن بياناتك، ولا يرسلها لأي طرف ثالث.

2. الاتصال بالإنترنت
يستخدم التطبيق الإنترنت في حالتين فقط:
- التحقق من وجود تحديث جديد للتطبيق (يتم تحميل ملف نصي صغير يحتوي على رقم الإصدار فقط، دون إرسال أي من بياناتك).
- عند اختيارك الشخصي لمشاركة كشف حساب أو نسخة احتياطية عبر تطبيقات أخرى (واتساب، البريد، إلخ) — وفي هذه الحالة أنت من يختار الوجهة، والتطبيق لا يرسل أي شيء تلقائياً.

3. الأذونات المطلوبة
- إذن الإشعارات: لعرض تذكير يومي اختياري يمكنك إيقافه من الإعدادات.
- إذن الوصول للملفات: فقط عند اختيارك تصدير أو استيراد نسخة احتياطية، ولا يتم الوصول لأي ملف آخر على جهازك.

4. لا إعلانات ولا تتبّع
التطبيق لا يحتوي على أي إعلانات، ولا يستخدم أي أدوات تحليل أو تتبع سلوك المستخدم (Analytics/Tracking)، ولا يشارك بياناتك مع أي شركة إعلانية.

5. النسخ الاحتياطي المحلي
عند استخدامك لميزة "تصدير نسخة احتياطية"، يُنشئ التطبيق ملف JSON يحتوي على بياناتك ويفتح قائمة المشاركة في نظام التشغيل لتختار أين تحفظه (جهازك، Google Drive، إلخ) — أنت المسؤول الوحيد عن مكان حفظ هذا الملف.

5.1 النسخ الاحتياطي السحابي الاختياري (Google Drive)
إذا اخترت تفعيل "النسخ الاحتياطي السحابي" من الإعدادات، سيطلب منك التطبيق تسجيل الدخول بحساب Google. عند الموافقة:
- يُخزَّن ملف نسخة احتياطية واحد فقط في مساحة خاصة بالتطبيق داخل حسابك على Google Drive (تسمى appDataFolder)، وهي مساحة مخفية لا تظهر في تطبيق Drive العادي ولا يمكن لأي تطبيق آخر الوصول إليها.
- التطبيق لا يطّلع على أي ملف آخر في حسابك على Drive ولا يطلب أي صلاحية عدا تخزين نسخته الخاصة.
- يمكنك إيقاف هذه الميزة وتسجيل الخروج في أي وقت من الإعدادات، وهذا لا يحذف النسخة المخزنة تلقائياً من Drive (يمكنك حذفها يدوياً من إعدادات حسابك في Google إذا رغبت).
- هذه الميزة اختيارية بالكامل؛ التطبيق يعمل بكامل وظائفه بدونها.

6. حذف البيانات
يمكنك حذف جميع بياناتك في أي وقت من داخل الإعدادات ← "حذف جميع البيانات". هذا الإجراء نهائي ولا يمكن التراجع عنه.

7. التواصل
لأي استفسار يخص الخصوصية، يمكنك التواصل مباشرة عبر واتساب من قسم "الدعم الفني" في الإعدادات.
''';

const _englishContent = '''
Privacy Policy - Daftar Al-Hisab

Last updated: 2026

Your privacy matters to us. This policy explains, clearly and accurately, how the "Daftar Al-Hisab" app handles your data.

1. Local storage only
All data you enter (worker names, workshops, journal entries, payments, settings) is stored exclusively on your device in a local database (SQLite). The app has no server of its own that receives or stores your data, and it never sends it to any third party.

2. Internet access
The app uses the internet in only two cases:
- Checking for a new app update (a small text file containing just a version number is downloaded — none of your data is sent).
- When you personally choose to share an account statement or a backup file through another app (WhatsApp, email, etc.) — you choose the destination; the app never sends anything automatically.

3. Permissions requested
- Notifications: to show an optional daily reminder you can turn off in Settings.
- File access: only when you choose to export or import a backup; no other files on your device are accessed.

4. No ads, no tracking
The app contains no ads, uses no analytics or user-behavior tracking tools, and does not share your data with any advertising company.

5. Local backups
When you use "Export backup", the app creates a JSON file with your data and opens the system share sheet so you can choose where to save it (your device, Google Drive, etc.) — you are solely responsible for where that file ends up.

5.1 Optional cloud backup (Google Drive)
If you choose to enable "Cloud backup" in Settings, the app will ask you to sign in with a Google account. If you agree:
- A single backup file is stored in an app-private space inside your Google Drive account (called appDataFolder), a hidden area not visible in the regular Drive app and not accessible to any other app.
- The app never sees any other file in your Drive account and requests no permission beyond storing its own backup.
- You can turn this off and sign out at any time from Settings; this does not automatically delete the stored backup from Drive (you can delete it manually from your Google account settings if you wish).
- This feature is entirely optional; the app works fully without it.

6. Deleting your data
You can delete all your data at any time from Settings → "Delete all data". This action is permanent and cannot be undone.

7. Contact
For any privacy question, you can reach out directly via WhatsApp from the "Support" section in Settings.
''';

const _turkishContent = '''
Gizlilik Politikası - Daftar Al-Hisab

Son güncelleme: 2026

Gizliliğiniz bizim için önemlidir. Bu politika, "Daftar Al-Hisab" uygulamasının verilerinizi nasıl işlediğini açık ve doğru bir şekilde açıklar.

1. Sadece yerel depolama
Girdiğiniz tüm veriler (işçi adları, atölyeler, günlük kayıtları, ödemeler, ayarlar) yalnızca cihazınızda yerel bir veritabanında (SQLite) saklanır. Uygulamanın verilerinizi alan veya saklayan kendi sunucusu yoktur ve verileriniz hiçbir üçüncü tarafa gönderilmez.

2. İnternet erişimi
Uygulama interneti yalnızca iki durumda kullanır:
- Yeni bir güncelleme olup olmadığını kontrol etmek (yalnızca bir sürüm numarası içeren küçük bir metin dosyası indirilir — verileriniz gönderilmez).
- Bir hesap ekstresini veya yedeği başka bir uygulama üzerinden (WhatsApp, e-posta vb.) paylaşmayı kişisel olarak seçtiğinizde — hedefi siz seçersiniz, uygulama otomatik olarak hiçbir şey göndermez.

3. İstenen izinler
- Bildirimler: Ayarlar'dan kapatabileceğiniz isteğe bağlı günlük hatırlatıcıyı göstermek için.
- Dosya erişimi: Yalnızca bir yedeği dışa/içe aktarmayı seçtiğinizde; cihazınızdaki başka hiçbir dosyaya erişilmez.

4. Reklam yok, takip yok
Uygulama hiçbir reklam içermez, hiçbir analiz veya kullanıcı davranışı takip aracı kullanmaz ve verilerinizi hiçbir reklam şirketiyle paylaşmaz.

5. Yerel yedekler
"Yedeği dışa aktar" özelliğini kullandığınızda, uygulama verilerinizi içeren bir JSON dosyası oluşturur ve nereye kaydedeceğinizi seçebilmeniz için sistem paylaşım menüsünü açar (cihazınız, Google Drive vb.) — bu dosyanın nerede saklandığından yalnızca siz sorumlusunuz.

5.1 İsteğe bağlı bulut yedekleme (Google Drive)
Ayarlar'dan "Bulut yedekleme"yi etkinleştirmeyi seçerseniz, uygulama sizden bir Google hesabıyla giriş yapmanızı isteyecektir. Kabul ederseniz:
- Google Drive hesabınızda uygulamaya özel bir alanda (appDataFolder olarak adlandırılır) tek bir yedek dosyası saklanır; bu, normal Drive uygulamasında görünmeyen ve başka hiçbir uygulamanın erişemediği gizli bir alandır.
- Uygulama Drive hesabınızdaki başka hiçbir dosyayı görmez ve kendi yedeğini saklamanın ötesinde hiçbir izin istemez.
- Bunu istediğiniz zaman Ayarlar'dan kapatabilir ve çıkış yapabilirsiniz; bu, Drive'da saklanan yedeği otomatik olarak silmez (isterseniz Google hesap ayarlarınızdan manuel olarak silebilirsiniz).
- Bu özellik tamamen isteğe bağlıdır; uygulama onsuz da tam olarak çalışır.

6. Verilerinizi silme
Verilerinizin tamamını istediğiniz zaman Ayarlar → "Tüm verileri sil" üzerinden silebilirsiniz. Bu işlem kalıcıdır ve geri alınamaz.

7. İletişim
Gizlilikle ilgili herhangi bir sorunuz için Ayarlar'daki "Destek" bölümünden WhatsApp üzerinden doğrudan iletişime geçebilirsiniz.
''';
