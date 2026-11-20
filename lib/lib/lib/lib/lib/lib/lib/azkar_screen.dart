import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/azkar.json').then((s) {
      if (mounted) setState(() => data = json.decode(s));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final tabs = [
      ('morning', isAr ? 'الصباح' : 'Morning'),
      ('evening', isAr ? 'المساء' : 'Evening'),
      ('after_prayer', isAr ? 'بعد الصلاة' : 'After Prayer'),
      ('sleep', isAr ? 'النوم' : 'Sleep'),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'الأذكار' : 'Azkar'),
          bottom: TabBar(isScrollable: true, tabs: [for (final t in tabs) Tab(text: t.$2)]),
        ),
        body: data == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  for (final t in tabs)
                    AzkarList(type: t.$1, items: List<Map<String, dynamic>>.from(data![t.$1])),
                ],
              ),
      ),
    );
  }
}

class AzkarList extends StatefulWidget {
  final String type;
  final List<Map<String, dynamic>> items;
  const AzkarList({super.key, required this.type, required this.items});

  @override
  State<AzkarList> createState() => _AzkarListState();
}

class _AzkarListState extends State<AzkarList> with AutomaticKeepAliveClientMixin {
  SharedPreferences? prefs;
  late List<int> done;

  @override
  bool get wantKeepAlive => true;

  String get _today {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  String _key(int i) => 'az_${_today}_${widget.type}_$i';

  @override
  void initState() {
    super.initState();
    done = List.filled(widget.items.length, 0);
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() {
        prefs = p;
        for (int i = 0; i < done.length; i++) {
          done[i] = p.getInt(_key(i)) ?? 0;
        }
      });
    });
  }

  void _tap(int i) {
    final total = widget.items[i]['count'] as int;
    if (done[i] >= total) return;
    setState(() => done[i]++);
    prefs?.setInt(_key(i), done[i]);
    if (done[i] >= total) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _reset() {
    setState(() {
      for (int i = 0; i < done.length; i++) {
        done[i] = 0;
        prefs?.remove(_key(i));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final finished = done.where((d) => d > 0).isNotEmpty;
    final completed = List.generate(done.length, (i) => done[i] >= (widget.items[i]['count'] as int))
        .where((c) => c)
        .length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: widget.items.isEmpty ? 0 : completed / widget.items.length,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Text('$completed/${widget.items.length}'),
              if (finished)
                IconButton(
                  tooltip: isAr ? 'إعادة' : 'Reset',
                  icon: const Icon(Icons.refresh),
                  onPressed: _reset,
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.items.length,
            itemBuilder: (context, i) {
              final item = widget.items[i];
              final total = item['count'] as int;
              final left = total - done[i];
              final isDone = left <= 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: isDone ? Colors.green.withOpacity(0.12) : null,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _tap(i),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          item['text'],
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontSize: 20, height: 1.9),
                        ),
                        if ((item['source'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(item['source'],
                              style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                        ],
                        const SizedBox(height: 12),
                        CircleAvatar(
                          backgroundColor: isDone ? Colors.green : Theme.of(context).colorScheme.primary,
                          child: isDone
                              ? const Icon(Icons.check, color: Colors.white)
                              : Text('$left', style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
