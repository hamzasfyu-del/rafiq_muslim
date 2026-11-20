import 'package:flutter/material.dart';
import 'prayer_screen.dart';
import 'quran_screen.dart';
import 'azkar_screen.dart';
import 'tasbih_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _pages = <Widget>[
    PrayerScreen(),
    QuranScreen(),
    AzkarScreen(),
    TasbihScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.access_time), label: isAr ? 'الصلاة' : 'Prayer'),
          NavigationDestination(icon: const Icon(Icons.menu_book), label: isAr ? 'القرآن' : 'Quran'),
          NavigationDestination(icon: const Icon(Icons.wb_sunny_outlined), label: isAr ? 'الأذكار' : 'Azkar'),
          NavigationDestination(icon: const Icon(Icons.touch_app), label: isAr ? 'المسبحة' : 'Tasbih'),
          NavigationDestination(icon: const Icon(Icons.settings), label: isAr ? 'الإعدادات' : 'Settings'),
        ],
      ),
    );
  }
}
