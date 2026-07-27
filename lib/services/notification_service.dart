import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_localizations.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int _dailyReminderId = 1001;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final String localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (_) {
      // Fall back to whatever the timezone package defaults to (UTC) if
      // detection fails; scheduling will still work, just possibly offset
      // from the device's local wall-clock time.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await init();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidImpl?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required AppLanguage language,
  }) async {
    await init();
    await _plugin.cancel(_dailyReminderId);

    final title = AppLocalizations.t('app_name', language);
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'تذكير يومي',
      channelDescription: 'تذكير يومي لتسجيل اليوميات والمصروفات',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    final body = language == AppLanguage.ar
        ? 'لا تنسَ تسجيل يوميات العمل والمدفوعات لهذا اليوم'
        : language == AppLanguage.tr
            ? 'Bugünün iş günlüğünü ve ödemelerini kaydetmeyi unutmayın'
            : "Don't forget to log today's work and payments";

    try {
      await _plugin.zonedSchedule(
        _dailyReminderId,
        title,
        body,
        _nextInstanceOfTime(hour, minute),
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // On some OEM devices exact/inexact alarm scheduling can throw if
      // permissions were revoked after the request; fail silently rather
      // than crashing the settings screen.
      debugPrint('Failed to schedule daily reminder: $e');
    }
  }

  Future<void> cancelDailyReminder() async {
    await init();
    await _plugin.cancel(_dailyReminderId);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
