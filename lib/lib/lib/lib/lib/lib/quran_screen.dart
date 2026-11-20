import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  String query = '';
  int? bmSurah, bmVerse;

  @override
  void initState() {
    super.initState();
    _loadBookmark();
  }

  Future<void> _loadBookmark() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      bmSurah = p.getInt('bm_surah');
      bmVerse = p.getInt('bm_verse');
    });
  }

  Future<void> _open(int surah, [int verse = 1]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SurahDetailScreen(surahNumber: surah, initialVerse: verse)),
    );
    _loadBookmark();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final surahs = List.generate(114, (i) => i + 1).where((n) {
      if (query.isEmpty) return true;
      final q = query.toLowerCase();
      return n.toString() == q ||
          quran.getSurahNameArabic(n).contains(query) ||
          quran.getSurahName(n).toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(isAr ? 'القرآن الكريم' : 'Holy Quran')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: isAr ? 'ابحث عن سورة...' : 'Search surah...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => query = v.trim()),
            ),
          ),
          if (bmSurah != null && query.isEmpty)
            Card(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.bookmark),
                title: Text(isAr ? 'متابعة القراءة' : 'Continue reading'),
                subtitle: Text(
                  '${isAr ? quran.getSurahNameArabic(bmSurah!) : quran.getSurahName(bmSurah!)}'
                  ' - ${isAr ? 'آية' : 'Verse'} $bmVerse',
                ),
                onTap: () => _open(bmSurah!, bmVerse ?? 1),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: surahs.length,
              itemBuilder: (context, i) {
                final n = surahs[i];
                return ListTile(
                  leading: CircleAvatar(child: Text('$n')),
                  title: Text(
                    isAr ? quran.getSurahNameArabic(n) : quran.getSurahName(n),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text('${isAr ? 'عدد الآيات:' : 'Verses:'} ${quran.getVerseCount(n)}'),
                  onTap: () => _open(n),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SurahDetailScreen extends StatefulWidget {
  final int surahNumber;
  final int initialVerse;
  const SurahDetailScreen({super.key, required this.surahNumber, this.initialVerse = 1});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  SharedPreferences? prefs;
  double fontSize = 26;
  int? bmSurah, bmVerse;

  bool get hasBasmala => widget.surahNumber != 1 && widget.surahNumber != 9;
  int get offset => hasBasmala ? 1 : 0;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() {
        prefs = p;
        fontSize = p.getDouble('quranFont') ?? 26;
        bmSurah = p.getInt('bm_surah');
        bmVerse = p.getInt('bm_verse');
      });
    });
  }

  void _setFont(double v) {
    final size = v.clamp(18.0, 44.0);
    setState(() => fontSize = size);
    prefs?.setDouble('quranFont', size);
  }

  Future<void> _bookmark(int verse) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    await prefs?.setInt('bm_surah', widget.surahNumber);
    await prefs?.setInt('bm_verse', verse);
    setState(() {
      bmSurah = widget.surahNumber;
      bmVerse = verse;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 1),
      content: Text(isAr ? 'تم حفظ العلامة عند الآية $verse' : 'Bookmarked verse $verse'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.surahNumber;
    final count = quran.getVerseCount(s);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(quran.getSurahNameArabic(s)),
        actions: [
          IconButton(icon: const Icon(Icons.text_decrease), onPressed: () => _setFont(fontSize - 2)),
          IconButton(icon: const Icon(Icons.text_increase), onPressed: () => _setFont(fontSize + 2)),
        ],
      ),
      body: prefs == null
          ? const Center(child: CircularProgressIndicator())
          : ScrollablePositionedList.builder(
              initialScrollIndex: (widget.initialVerse - 1 + offset).clamp(0, count + offset - 1),
              itemCount: count + offset,
              itemBuilder: (context, i) {
                if (hasBasmala && i == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(quran.basmala,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
                  );
                }
                final verse = i - offset + 1;
                final isBm = bmSurah == s && bmVerse == verse;
                return InkWell(
                  onTap: () => _bookmark(verse),
                  child: Container(
                    color: isBm ? cs.primary.withOpacity(0.15) : null,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text(
                      quran.getVerse(s, verse, verseEndSymbol: true),
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(fontSize: fontSize, height: 1.9),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
