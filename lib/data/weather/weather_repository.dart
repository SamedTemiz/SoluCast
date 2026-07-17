import '../location/saved_location.dart';
import 'weather_data.dart';

/// Hava veri kaynağı — **sağlayıcı-bağımsız** arayüz (data-sources.md O2 önlemi:
/// OpenWeatherMap↔Open-Meteo geçişi 1 günlük iş olsun diye). UI ve skor yalnız
/// bu arayüze bağlıdır. Cache + offline fallback uygulama detayıdır.
abstract interface class WeatherRepository {
  /// [location] için anlık hava; ağ başarısızsa cache'ten (staleness [WeatherData.fetchedAt]).
  /// Hiç veri yoksa `null` — uygulama yalnız astronomiyle çalışmaya devam eder (F3.4).
  Future<WeatherData?> fetchCurrent(SavedLocation location);
}
