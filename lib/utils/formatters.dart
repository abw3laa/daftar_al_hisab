import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _number = NumberFormat('#,##0.##', 'en_US');

  static String amount(double value) => _number.format(value);

  static String currency(double value, String symbol) =>
      '${_number.format(value)} $symbol';

  static String date(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  static String dateLongArabic(DateTime date) {
    const weekdays = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday، ${date.day} $month ${date.year}';
  }

  static String relativeTime(DateTime? dt) {
    if (dt == null) return 'لا يوجد نشاط بعد';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inDays == 0) {
      return 'اليوم، ${DateFormat('hh:mm a').format(dt)}';
    }
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return date(dt);
  }
}
