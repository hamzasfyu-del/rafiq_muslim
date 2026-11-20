import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class City {
  final String en, ar;
  final double lat, lng;
  const City(this.en, this.ar, this.lat, this.lng);
}

const List<City> kCities = [
  City('Damascus', 'دمشق', 33.5138, 36.2765),
  City('Aleppo', 'حلب', 36.2021, 37.1343),
  City('Mecca', 'مكة المكرمة', 21.3891, 39.8579),
  City('Medina', 'المدينة المنورة', 24.5247, 39.5692),
  City('Riyadh', 'الرياض', 24.7136, 46.6753),
  City('Cairo', 'القاهرة', 30.0444, 31.2357),
  City('Dubai', 'دبي', 25.2048, 55.2708),
  City('Amman', 'عمّان', 31.9454, 35.9284),
  City('Baghdad', 'بغداد', 33.3152, 44.3661),
  City('Kuwait City', 'مدينة الكويت', 29.3759, 47.9774),
  City('Doha', 'الدوحة', 25.2854, 51.5310),
  City('Istanbul', 'إسطنبول', 41.0082, 28.9784),
  City('Casablanca', 'الدار البيضاء', 33.5731, -7.5898),
  City('Tunis', 'تونس', 36.8065, 10.1815),
  City('Algiers', 'الجزائر', 36.7538, 3.0588),
  City('London', 'لندن', 51.5072, -0.1276),
];

const Map<String, List<String>> kMethodLabels = {
  'muslim_world_league': ['رابطة العالم الإسلامي', 'Muslim World League'],
  'umm_al_qura': ['أم القرى', 'Umm al-Qura'],
  'egyptian': ['الهيئة المصرية', 'Egyptian'],
  'karachi': ['كراتشي', 'Karachi'],
  'dubai': ['دبي', 'Dubai'],
  'kuwait': ['الكويت', 'Kuwait'],
  'qatar': ['قطر', 'Qatar'],
  'turkey': ['تركيا', 'Turkey'],
};

class PrayerService {
  static Coordinates coordinates(SharedPreferences p) =>
      Coordinates(p.getDouble('lat') ?? 33.5138, p.getDouble('lng') ?? 36.2765);

  static CalculationParameters params(SharedPreferences p) {
    final name = p.getString('method') ?? 'muslim_world_league';
    final method = CalculationMethod.values.firstWhere(
      (m) => m.name == name,
      orElse: () => CalculationMethod.muslim_world_league,
    );
    final params = method.getParameters();
    params.madhab = p.getString('madhab') == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
    return params;
  }

  static PrayerTimes forDay(SharedPreferences p, DateTime day) =>
      PrayerTimes(coordinates(p), DateComponents.from(day), params(p));

  static Future<Position?> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return null;
    }
    return Geolocator.getCurrentPosition();
  }
}
