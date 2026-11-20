import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  SharedPreferences? prefs;
  int count = 0;
  int target = 33;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() {
        prefs = p;
        count = p.getInt('tasbih_count') ?? 0;
        target = p.getInt('tasbih_target') ?? 33;
      });
    });
  }

  void _inc() {
    setState(() => count++);
    prefs?.setInt('tasbih_count', count);
    if (count % target == 0) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _reset() {
    setState(() => count = 0);
    prefs?.setInt('tasbih_count', 0);
  }

  void _setTarget(int t) {
    setState(() => target = t);
    prefs?.setInt('tasbih_target', t);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final cs = Theme.of(context).colorScheme;
    final progress = (count % target) / target;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'المسبحة' : 'Tasbih'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _reset)],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final t in [33, 99, 100])
                  ChoiceChip(label: Text('$t'), selected: target == t, onSelected: (_) => _setTarget(t)),
              ],
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _inc,
              child: SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(value: progress, strokeWidth: 10),
                    ),
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primaryContainer),
                      alignment: Alignment.center,
                      child: Text('$count',
                          style: TextStyle(
                              fontSize: 64, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(isAr ? 'اضغط للتسبيح' : 'Tap to count', style: TextStyle(color: Theme.of(context).hintColor)),
          ],
        ),
      ),
    );
  }
}
