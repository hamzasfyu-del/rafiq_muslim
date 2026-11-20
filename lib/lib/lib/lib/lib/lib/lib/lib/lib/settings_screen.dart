import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'notification_service.dart';
import 'prayer_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => prefs = p);
    });
  }

  Future<void> _reschedule({bool? ar}) async {
    final isAr = ar ?? Localizations.localeOf(context).languageCode == 'ar';
    try {
      await NotificationService.scheduleAll(prefs!, isAr);
    } catch (_) {}
  }

  Future<void> _useGps(bool isAr) async {
    final pos = await PrayerService.currentPosition();
    if (!mounted) return;
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'تعذّر تحديد الموقع' : 'Could not get location')),
      );
      return;
    }
    await prefs!.setDouble('lat', pos.latitude);
    await prefs!.setDouble('lng', pos.longitude);
    await prefs!.setString('country', 'GPS');
    await _reschedule();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = prefs;

    if (p == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final country = p.getString('country') ?? 'Damascus';
    final method = p.getString('method') ?? 'muslim_world_league';
    final madhab = p.getString('madhab') ?? 'shafi';

    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'الإعدادات' : 'Settings')),
      body: ListView(
        children: [
          _header(isAr ? 'عام' : 'General'),
          SwitchListTile(
            title: Text(isAr ? 'الوضع الداكن' : 'Dark Mode'),
            secondary: const Icon(Icons.dark_mode),
            value: isDark,
            onChanged: (v) => RafiqMuslimApp.of(context)?.toggleTheme(v),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(isAr ? 'اللغة' : 'Language'),
            trailing: DropdownButton<String>(
              value: isAr ? 'ar' : 'en',
              items: const [
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (v) async {
                if (v == null) return;
                await RafiqMuslimApp.of(context)?.changeLanguage(v);
                await _reschedule(ar: v == 'ar');
              },
            ),
          ),
          _header(isAr ? 'مواقيت الصلاة' : 'Prayer Times'),
          ListTile(
            leading: const Icon(Icons.location_city),
            title: Text(isAr ? 'المدينة' : 'City'),
            trailing: DropdownButton<String>(
              value: kCities.any((c) => c.en == country) ? country : null,
              hint: Text(isAr ? 'موقعي الحالي' : 'Current location'),
              items: kCities
                  .map((c) => DropdownMenuItem(value: c.en, child: Text(isAr ? c.ar : c.en)))
                  .toList(),
              onChanged: (v) async {
                final c = kCities.firstWhere((c) => c.en == v);
                await p.setString('country', c.en);
                await p.setDouble('lat', c.lat);
                await p.setDouble('lng', c.lng);
                await _reschedule();
                setState(() {});
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.my_location),
            title: Text(isAr ? 'استخدم موقعي الحالي (GPS)' : 'Use current location (GPS)'),
            onTap: () => _useGps(isAr),
          ),
          ListTile(
            leading: const Icon(Icons.calculate),
            title: Text(isAr ? 'طريقة الحساب' : 'Calculation method'),
            trailing: DropdownButton<String>(
              value: kMethodLabels.containsKey(method) ? method : 'muslim_world_league',
              items: kMethodLabels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(isAr ? e.value[0] : e.value[1])))
                  .toList(),
              onChanged: (v) async {
                await p.setString('method', v!);
                await _reschedule();
                setState(() {});
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: Text(isAr ? 'المذهب (للعصر)' : 'Madhab (Asr)'),
            trailing: DropdownButton<String>(
              value: madhab,
              items: [
                DropdownMenuItem(value: 'shafi', child: Text(isAr ? 'الجمهور' : 'Shafi / Majority')),
                DropdownMenuItem(value: 'hanafi', child: Text(isAr ? 'الحنفي' : 'Hanafi')),
              ],
              onChanged: (v) async {
                await p.setString('madhab', v!);
                await _reschedule();
                setState(() {});
              },
            ),
          ),
          _header(isAr ? 'الإشعارات' : 'Notifications'),
          SwitchListTile(
            title: Text(isAr ? 'تنبيه وقت الصلاة' : 'Prayer time alerts'),
            secondary: const Icon(Icons.notifications_active),
            value: p.getBool('notifPrayer') ?? true,
            onChanged: (v) async {
              await p.setBool('notifPrayer', v);
              await _reschedule();
              setState(() {});
            },
          ),
          SwitchListTile(
            title: Text(isAr ? 'تذكير أذكار الصباح والمساء' : 'Morning/Evening azkar reminders'),
            secondary: const Icon(Icons.wb_sunny),
            value: p.getBool('notifAzkar') ?? true,
            onChanged: (v) async {
              await p.setBool('notifAzkar', v);
              await _reschedule();
              setState(() {});
            },
          ),
          _header(isAr ? 'القرآن' : 'Quran'),
          ListTile(
            leading: const Icon(Icons.format_size),
            title: Text(isAr ? 'حجم الخط' : 'Font size'),
            subtitle: Slider(
              min: 18,
              max: 44,
              divisions: 13,
              value: (p.getDouble('quranFont') ?? 26).clamp(18, 44),
              onChanged: (v) {
                p.setDouble('quranFont', v);
                setState(() {});
              },
            ),
          ),
          _header(isAr ? 'حول' : 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(isAr ? 'عن التطبيق' : 'About the app'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: isAr ? 'رفيق المسلم' : 'Rafiq Al-Muslim',
              applicationVersion: '1.0.0',
              applicationIcon: const Icon(Icons.mosque, size: 40, color: Color(0xFF1B7F5C)),
              children: [
                Text(isAr
                    ? 'القرآن الكريم والأذكار ومواقيت الصلاة في تطبيق واحد.'
                    : 'Quran, Azkar and prayer times in one app.'),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _header(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(t,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
      );
}
