import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'prayer_service.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  SharedPreferences? prefs;
  PrayerTimes? prayerTimes;
  Timer? _timer;
  Duration remaining = Duration.zero;
  Prayer nextPrayer = Prayer.none;
  int _day = DateTime.now().day;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _load() async {
    prefs ??= await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _day = DateTime.now().day;
      prayerTimes = PrayerService.forDay(prefs!, DateTime.now());
    });
    _tick();
  }

  void _tick() {
    if (prayerTimes == null || prefs == null || !mounted) return;
    final now = DateTime.now();
    if (now.day != _day) {
      _load();
      return;
    }
    var next = prayerTimes!.nextPrayer();
    DateTime? t = next == Prayer.none ? null : prayerTimes!.timeForPrayer(next);

    if (t == null) {
      t = PrayerService.forDay(prefs!, now.add(const Duration(days: 1))).fajr;
      next = Prayer.fajr;
    }
    final diff = t.difference(now);
    setState(() {
      nextPrayer = next;
      remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (prayerTimes == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final fmt = DateFormat.jm(isAr ? 'ar' : 'en');
    final cs = Theme.of(context).colorScheme;
    final countdown =
        '${_two(remaining.inHours)}:${_two(remaining.inMinutes % 60)}:${_two(remaining.inSeconds % 60)}';

    final rows = [
      (Prayer.fajr, isAr ? 'الفجر' : 'Fajr', prayerTimes!.fajr),
      (Prayer.sunrise, isAr ? 'الشروق' : 'Sunrise', prayerTimes!.sunrise),
      (Prayer.dhuhr, isAr ? 'الظهر' : 'Dhuhr', prayerTimes!.dhuhr),
      (Prayer.asr, isAr ? 'العصر' : 'Asr', prayerTimes!.asr),
      (Prayer.maghrib, isAr ? 'المغرب' : 'Maghrib', prayerTimes!.maghrib),
      (Prayer.isha, isAr ? 'العشاء' : 'Isha', prayerTimes!.isha),
    ];
    final nextName = rows.firstWhere((r) => r.$1 == nextPrayer, orElse: () => rows.first).$2;

    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'مواقيت الصلاة' : 'Prayer Times')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Text(
                  isAr ? 'الوقت المتبقي لصلاة $nextName' : 'Time until $nextName',
                  style: TextStyle(color: cs.onPrimary.withOpacity(0.8), fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(countdown,
                    style: TextStyle(color: cs.onPrimary, fontSize: 40, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final r in rows)
            Card(
              color: r.$1 == nextPrayer ? cs.primaryContainer : null,
              child: ListTile(
                leading: Icon(r.$1 == nextPrayer ? Icons.notifications_active : Icons.access_time),
                title: Text(r.$2, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                trailing: Text(fmt.format(r.$3), style: const TextStyle(fontSize: 18)),
              ),
            ),
        ],
      ),
    );
  }
}
