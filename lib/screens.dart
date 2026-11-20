import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:quran/quran.dart' as quran;

class OnboardingScreen extends StatefulWidget {
  final Function(String lang, String country) onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String selectedLang = 'ar';
  String selectedCountry = 'Syria';

  final Map<String, String> countries = {
    'Syria': 'سوريا - دمشق',
    'Saudi Arabia': 'السعودية - مكة المكرمة',
    'Egypt': 'مصر - القاهرة',
    'UAE': 'الإمارات - دبي',
    'Jordan': 'الأردن - عمّان',
    'Iraq': 'العراق - بغداد',
  };

  @override
  Widget build(BuildContext context) {
    bool isAr = selectedLang == 'ar';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mosque_rounded, size: 85, color: Colors.teal),
              const SizedBox(height: 16),
              Text(
                isAr ? 'أهلاً بك في رفيق المسلم' : 'Welcome to Muslim Companion',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              Text(isAr ? 'اختر اللغة:' : 'Choose Language:'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('العربية')),
                      selected: selectedLang == 'ar',
                      onSelected: (_) => setState(() => selectedLang = 'ar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('English')),
                      selected: selectedLang == 'en',
                      onSelected: (_) => setState(() => selectedLang = 'en'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(isAr ? 'حدد الدولة لمواقيت الصلاة:' : 'Select Country:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCountry,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: countries.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(isAr ? e.value : e.key))).toList(),
                onChanged: (val) => setState(() => selectedCountry = val!),
              ),
              const SizedBox(height: 35),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 15)),
                onPressed: () => widget.onComplete(selectedLang, selectedCountry),
                child: Text(isAr ? 'ابدأ الاستخدام' : 'Continue', style: const TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SurahListScreen extends StatelessWidget {
  final bool isAr;
  const SurahListScreen({super.key, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'فهرس السور' : 'Surahs Index')),
      body: ListView.separated(
        itemCount: 114,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          int s = index + 1;
          return ListTile(
            leading: CircleAvatar(backgroundColor: Colors.teal.withOpacity(0.15), child: Text('$s', style: const TextStyle(color: Colors.teal))),
            title: Text(isAr ? quran.getSurahNameArabic(s) : quran.getSurahName(s), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            subtitle: Text(isAr ? 'الآيات: ${quran.getVerseCount(s)}' : 'Verses: ${quran.getVerseCount(s)}'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahDetailScreen(surahNumber: s, isAr: isAr))),
          );
        },
      ),
    );
  }
}

class SurahDetailScreen extends StatelessWidget {
  final int surahNumber;
  final bool isAr;
  const SurahDetailScreen({super.key, required this.surahNumber, required this.isAr});

  @override
  Widget build(BuildContext context) {
    StringBuffer text = StringBuffer();
    for (int i = 1; i <= quran.getVerseCount(surahNumber); i++) {
      text.write('${quran.getVerse(surahNumber, i, verseEndSymbol: true)} ');
    }
    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'سورة ${quran.getSurahNameArabic(surahNumber)}' : quran.getSurahName(surahNumber))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (surahNumber != 1 && surahNumber != 9)
              const Padding(padding: EdgeInsets.only(bottom: 16), child: Text(quran.basmala, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal))),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border.all(color: Colors.teal), borderRadius: BorderRadius.circular(12)),
              child: Text(text.toString(), textAlign: TextAlign.justify, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 24, height: 2.1)),
            ),
          ],
        ),
      ),
    );
  }
}

class AdhkarScreen extends StatefulWidget {
  final bool isAr;
  const AdhkarScreen({super.key, required this.isAr});

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> {
  List<dynamic> morning = [];
  List<dynamic> evening = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = json.decode(await rootBundle.loadString('assets/azkar.json'));
      setState(() {
        morning = List<Map<String, dynamic>>.from(data['morning'] ?? []);
        evening = List<Map<String, dynamic>>.from(data['evening'] ?? []);
      });
    } catch (_) {
      setState(() {
        morning = [{'text': 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ.', 'count': 1}, {'text': 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ.', 'count': 3}];
        evening = [{'text': 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ.', 'count': 1}, {'text': 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ.', 'count': 3}];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isAr ? 'الأذكار' : 'Adhkar'),
          bottom: TabBar(tabs: [Tab(text: widget.isAr ? 'أذكار الصباح' : 'Morning'), Tab(text: widget.isAr ? 'أذكار المساء' : 'Evening')]),
        ),
        body: TabBarView(children: [_list(morning), _list(evening)]),
      ),
    );
  }

  Widget _list(List<dynamic> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        int rem = items[i]['count'] ?? 1;
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: InkWell(
            onTap: rem > 0 ? () => setState(() => items[i]['count'] = rem - 1) : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(items[i]['text'] ?? '', textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 20, height: 1.8)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: rem == 0 ? Colors.green : Colors.teal,
                    child: Center(child: Text(rem == 0 ? '✓' : '$rem', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class PrayerTimesScreen extends StatefulWidget {
  final bool isAr;
  final String country;
  const PrayerTimesScreen({super.key, required this.isAr, required this.country});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  late Timer _timer;
  late PrayerTimes _pt;
  Duration _rem = Duration.zero;
  String _nextName = '';

  @override
  void initState() {
    super.initState();
    Coordinates c = Coordinates(33.5138, 36.2765);
    if (widget.country == 'Saudi Arabia') c = Coordinates(21.3891, 39.8579);
    if (widget.country == 'Egypt') c = Coordinates(30.0444, 31.2357);
    if (widget.country == 'UAE') c = Coordinates(25.2048, 55.2708);
    if (widget.country == 'Jordan') c = Coordinates(31.9454, 35.9284);
    if (widget.country == 'Iraq') c = Coordinates(33.3152, 44.3661);
    _pt = PrayerTimes.today(c, CalculationMethod.muslim_world_league.getParameters());
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    final next = _pt.nextPrayer();
    DateTime? t = _pt.timeForPrayer(next);
if (t == null) {
t = _pt.fajr.add(const Duration(days: 1));
_nextName = widget.isAr ? 'الفجر' : 'Fajr';
} else {
_nextName = next.name.toUpperCase();
}
setState(() => _rem = t!.difference(now));
}
@override
void dispose() {
_timer.cancel();
super.dispose();
}
@override
Widget build(BuildContext context) {
final f = DateFormat.jm();
String cd = '${_rem.inHours.toString().padLeft(2, '0')}:${(_rem.inMinutes % 60).toString().padLeft(2, '0')}:${(_rem.inSeconds % 60).toString().padLeft(2, '0')}';
return Scaffold(
appBar: AppBar(title: Text(widget.isAr ? 'مواقيت الصلاة' : 'Prayer Times')),
body: Padding(
padding: const EdgeInsets.all(16),
child: Column(
children: [
Container(
width: double.infinity,
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(16)),
child: Column(
children: [
Text(widget.isAr ? 'المتبقي للصلاة القادمة ($_nextName)' : 'Next: $_nextName', style: const TextStyle(color: Colors.white70, fontSize: 16)),
Text(cd, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
],
),
),
const SizedBox(height: 16),
Expanded(
child: ListView(
children: [
_row(widget.isAr ? 'الفجر' : 'Fajr', f.format(_pt.fajr)),
_row(widget.isAr ? 'الظهر' : 'Dhuhr', f.format(_pt.dhuhr)),
_row(widget.isAr ? 'العصر' : 'Asr', f.format(_pt.asr)),
_row(widget.isAr ? 'المغرب' : 'Maghrib', f.format(_pt.maghrib)),
_row(widget.isAr ? 'العشاء' : 'Isha', f.format(_pt.isha)),
],
),
),
],
),
),
);
}
Widget _row(String n, String t) => Card(child: ListTile(title: Text(n, style: const TextStyle(fontWeight: FontWeight.bold)), trailing: Text(t, style: const TextStyle(color: Colors.teal, fontSize: 18))));
}
