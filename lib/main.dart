import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'notification_service.dart';
import 'onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final prefs = await SharedPreferences.getInstance();
  final isFirstTime = prefs.getBool('isFirstTime') ?? true;
  final lang = prefs.getString('language') ?? 'ar';
  final isDark = prefs.getBool('isDark') ?? false;

  try {
    await NotificationService.init();
    if (!isFirstTime) {
      await NotificationService.scheduleAll(prefs, lang == 'ar');
    }
  } catch (e) {
    debugPrint('Notification init error: $e');
  }

  runApp(RafiqMuslimApp(isFirstTime: isFirstTime, initialLang: lang, initialDark: isDark));
}

class RafiqMuslimApp extends StatefulWidget {
  final bool isFirstTime;
  final String initialLang;
  final bool initialDark;

  const RafiqMuslimApp({
    super.key,
    required this.isFirstTime,
    required this.initialLang,
    required this.initialDark,
  });

  static RafiqMuslimAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<RafiqMuslimAppState>();

  @override
  State<RafiqMuslimApp> createState() => RafiqMuslimAppState();
}

class RafiqMuslimAppState extends State<RafiqMuslimApp> {
  late String _language;
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLang;
    _isDark = widget.initialDark;
  }

  Future<void> changeLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    setState(() => _language = lang);
  }

  Future<void> toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDark);
    setState(() => _isDark = isDark);
  }

  ThemeData _theme(Brightness b) => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1B7F5C),
        brightness: b,
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (_) => _language == 'ar' ? 'رفيق المسلم' : 'Rafiq Al-Muslim',
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(_language),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: widget.isFirstTime ? OnboardingScreen() : HomeScreen(),
    );
  }
}
