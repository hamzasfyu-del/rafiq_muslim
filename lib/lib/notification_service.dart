import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'prayer_service.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    final name = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(name));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
  }

  static Future<void> scheduleAll(SharedPreferences prefs, bool isAr) async {
    await _plugin.cancelAll();
    final prayerOn = prefs.getBool('notifPrayer') ?? true;
    final azkarOn = prefs.getBool('notifAzkar') ?? true;
    final now = DateTime.now();

    for (int d = 0; d < 7; d++) {
      final t = PrayerService.forDay(prefs, now.add(Duration(days: d)));
      final base = d * 20;

      if (prayerOn) {
        final prayers = [
          (t.fajr, 'الفجر', 'Fajr'),
          (t.dhuhr, 'الظهر', 'Dhuhr'),
          (t.asr, 'العصر', 'Asr'),
          (t.maghrib, 'المغرب', 'Maghrib'),
          (t.isha, 'العشاء', 'Isha'),
        ];
        for (int i = 0; i < prayers.length; i++) {
          final p = prayers[i];
          await _schedule(
            base + i,
            isAr ? 'حان وقت الصلاة' : 'Prayer Time',
            isAr ? 'حان الآن موعد صلاة ${p.$2}' : "It's time for ${p.$3}",
            p.$1,
            'prayer_channel',
            isAr ? 'مواقيت الصلاة' : 'Prayer Times',
          );
        }
      }

      if (azkarOn) {
        await _schedule(
          base + 10,
          isAr ? 'أذكار الصباح' : 'Morning Azkar',
          isAr ? 'لا تنسَ أذكار الصباح' : "Don't forget your morning azkar",
          t.fajr.add(const Duration(minutes: 30)),
          'azkar_channel',
          isAr ? 'الأذكار' : 'Azkar',
        );
        await _schedule(
          base + 11,
          isAr ? 'أذكار المساء' : 'Evening Azkar',
          isAr ? 'حان وقت أذكار المساء' : 'Time for your evening azkar',
          t.asr.add(const Duration(minutes: 30)),
          'azkar_channel',
          isAr ? 'الأذكار' : 'Azkar',
        );
      }
    }
  }

  static Future<void> _schedule(
    int id,
    String title,
    String body,
    DateTime time,
    String channelId,
    String channelName,
  ) async {
    if (!time.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(time, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
