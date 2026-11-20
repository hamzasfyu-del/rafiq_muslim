import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'main.dart';
import 'notification_service.dart';
import 'prayer_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String selectedLang = 'ar';
  City selectedCity = kCities.first;
  double? gpsLat, gpsLng;
  bool loadingGps = false;

  Future<void> _useGps() async {
    setState(() => loadingGps = true);
    final pos = await PrayerService.currentPosition();
    if (!mounted) return;
    setState(() {
      loadingGps = false;
      if (pos != null) {
        gpsLat = pos.latitude;
        gpsLng = pos.longitude;
      }
    });
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(selectedLang == 'ar'
            ? 'تعذّر تحديد الموقع، اختر مدينة يدوياً'
            : 'Could not get location, please pick a city'),
      ));
    }
  }

  Future<void> _completeSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    final useGps = gpsLat != null;
    await prefs.setString('country', useGps ? 'GPS' : selectedCity.en);
    await prefs.setDouble('lat', useGps ? gpsLat! : selectedCity.lat);
    await prefs.setDouble('lng', useGps ? gpsLng! : selectedCity.lng);

    try {
      await NotificationService.scheduleAll(prefs, selectedLang == 'ar');
    } catch (_) {}

    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = selectedLang == 'ar';
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.mosque, size: 72, color: Color(0xFF1B7F5C)),
              const SizedBox(height: 12),
              Text(
                isAr ? 'رفيق المسلم' : 'Rafiq Al-Muslim',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: primary),
              ),
              const SizedBox(height: 4),
              Text(
                isAr ? 'القرآن • الأذكار • مواقيت الصلاة' : 'Quran • Azkar • Prayer Times',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: 32),
              Text(isAr ? 'اختر اللغة' : 'Select Language',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('العربية'),
                    selected: selectedLang == 'ar',
                    onSelected: (_) {
                      setState(() => selectedLang = 'ar');
                      RafiqMuslimApp.of(context)?.changeLanguage('ar');
                    },
                  ),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: const Text('English'),
                    selected: selectedLang == 'en',
                    onSelected: (_) {
                      setState(() => selectedLang = 'en');
                      RafiqMuslimApp.of(context)?.changeLanguage('en');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(isAr ? 'حدد موقعك لمواقيت الصلاة' : 'Select your location',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: loadingGps ? null : _useGps,
                icon: loadingGps
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(gpsLat != null ? Icons.check_circle : Icons.my_location),
                label: Text(gpsLat != null
                    ? (isAr ? 'تم تحديد موقعك' : 'Location detected')
                    : (isAr ? 'استخدم موقعي الحالي' : 'Use my current location')),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
              const SizedBox(height: 12),
              Text(isAr ? 'أو اختر مدينة' : 'or choose a city'),
              DropdownButton<City>(
                value: selectedCity,
                isExpanded: true,
                items: kCities
                    .map((c) => DropdownMenuItem(value: c, child: Text(isAr ? c.ar : c.en)))
                    .toList(),
                onChanged: (c) => setState(() {
                  selectedCity = c!;
                  gpsLat = null;
                  gpsLng = null;
                }),
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _completeSetup,
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: Text(isAr ? 'ابدأ الآن' : 'Start Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
