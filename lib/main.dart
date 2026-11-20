import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MuslimApp(
    isFirstTime: prefs.getBool('isFirstTime') ?? true,
    initialLang: prefs.getString('lang') ?? 'ar',
    initialDark: prefs.getBool('isDark') ?? false,
    initialCountry: prefs.getString('country') ?? 'Syria',
  ));
}

class MuslimApp extends StatefulWidget {
  final bool isFirstTime;
  final String initialLang;
  final bool initialDark;
  final String initialCountry;
  const MuslimApp({super.key, required this.isFirstTime, required this.initialLang, required this.initialDark, required this.initialCountry});

  @override
  State<MuslimApp> createState() => _MuslimAppState();
}

class _MuslimAppState extends State<MuslimApp> {
  late String _lang = widget.initialLang;
  late bool _isDark = widget.initialDark;
  late String _country = widget.initialCountry;
  late bool _isFirstTime = widget.isFirstTime;

  void _save({String? lang, bool? isDark, String? country, bool? isFirstTime}) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (lang != null) { _lang = lang; prefs.setString('lang', lang); }
      if (isDark != null) { _isDark = isDark; prefs.setBool('isDark', isDark); }
      if (country != null) { _country = country; prefs.setString('country', country); }
      if (isFirstTime != null) { _isFirstTime = isFirstTime; prefs.setBool('isFirstTime', isFirstTime); }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(_lang),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      theme: ThemeData(brightness: Brightness.light, primarySwatch: Colors.teal),
      darkTheme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.teal),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: _isFirstTime
          ? OnboardingScreen(onComplete: (l, c) => _save(lang: l, country: c, isFirstTime: false))
          : HomeScreen(lang: _lang, isDark: _isDark, country: _country, onLang: (v) => _save(lang: v), onDark: (v) => _save(isDark: v)),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final String lang;
  final bool isDark;
  final String country;
  final Function(String) onLang;
  final Function(bool) onDark;
  const HomeScreen({super.key, required this.lang, required this.isDark, required this.country, required this.onLang, required this.onDark});

  @override
  Widget build(BuildContext context) {
    bool isAr = lang == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'رفيق المسلم' : 'Muslim Companion'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(lang: lang, isDark: isDark, onLang: onLang, onDark: onDark))),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment.center,
          children: [
            _btn(context, isAr ? 'القرآن الكريم' : 'Holy Quran', Icons.menu_book, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahListScreen(isAr: isAr)))),
            const SizedBox(height: 18),
            _btn(context, isAr ? 'الأذكار' : 'Adhkar', Icons.wb_sunny, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdhkarScreen(isAr: isAr)))),
            const SizedBox(height: 18),
            _btn(context, isAr ? 'مواقيت الصلاة' : 'Prayer Times', Icons.mosque, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrayerTimesScreen(isAr: isAr, country: country)))),
          ],
        ),
      ),
    );
  }

  Widget _btn(BuildContext context, String t, IconData i, Color c, VoidCallback tap) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: c)),
      tileColor: c.withOpacity(0.1),
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(backgroundColor: c, child: Icon(i, color: Colors.white)),
      title: Text(t, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: tap,
    );
  }
}

class SettingsScreen extends StatelessWidget {
  final String lang;
  final bool isDark;
  final Function(String) onLang;
  final Function(bool) onDark;
  const SettingsScreen({super.key, required this.lang, required this.isDark, required this.onLang, required this.onDark});

  @override
  Widget build(BuildContext context) {
    bool isAr = lang == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'الإعدادات' : 'Settings')),
      body: ListView(
        children: [
          ListTile(
            title: Text(isAr ? 'اللغة' : 'Language'),
            trailing: DropdownButton<String>(
              value: lang,
              items: const [DropdownMenuItem(value: 'ar', child: Text('العربية')), DropdownMenuItem(value: 'en', child: Text('English'))],
              onChanged: (v) { if (v != null) onLang(v); },
            ),
          ),
          SwitchListTile(title: Text(isAr ? 'الوضع الداكن' : 'Dark Mode'), value: isDark, onChanged: onDark),
        ],
      ),
    );
  }
}
