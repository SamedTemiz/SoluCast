import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/location/saved_location.dart';
import '../../data/prefs/preferences.dart';
import '../../data/weather/open_meteo_weather_repository.dart';
import '../../data/weather/weather_data.dart';
import '../../data/weather/weather_repository.dart';
import '../today/today_providers.dart';

/// Hava kaynağı — Open-Meteo (sağlayıcı-bağımsız arayüz arkasında).
final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return OpenMeteoWeatherRepository(
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

/// Bir konum için hava — async. Ağ/cache detayı repo'da. Hata → null
/// (uygulama astronomiyle çalışmaya devam eder, F3.4).
final weatherProvider =
    FutureProvider.family<WeatherData?, SavedLocation>((ref, location) async {
  try {
    return await ref.watch(weatherRepositoryProvider).fetchCurrent(location);
  } catch (_) {
    return null;
  }
});

/// Aktif konumun havası.
final activeWeatherProvider = FutureProvider<WeatherData?>((ref) {
  final location = ref.watch(activeLocationProvider);
  return ref.watch(weatherProvider(location).future);
});

/// Bugünün skoru — hava **varsa** dahil edilmiş hali. Astronomi tabanı
/// [todayResultProvider]'dan anında gelir (ilk render ağ BEKLEMEZ); hava
/// çözülünce skor basınç faktörüyle yeniden hesaplanır (F3.2).
final todayScoredProvider = Provider<DayResult>((ref) {
  final base = ref.watch(todayResultProvider);
  final weather = ref.watch(activeWeatherProvider).asData?.value;
  if (weather == null) return base;

  final engine = ref.watch(solunarEngineProvider);
  return DayResult(
    location: base.location,
    localDate: base.localDate,
    ephemeris: base.ephemeris,
    solunar: engine.evaluate(base.ephemeris, weather: weather.toScoreInput()),
  );
});
