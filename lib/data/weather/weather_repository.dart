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

/// Optional capability for an explicit user-initiated refresh. Keeping this
/// separate preserves lightweight repositories and tests that only implement
/// the offline-friendly base contract.
abstract interface class RefreshableWeatherRepository {
  /// Returns true only when a fresh network response was stored. A false
  /// result means callers should keep rendering their existing cache instead
  /// of invalidating it and immediately making the same request again.
  Future<bool> refreshCurrent(SavedLocation location);
}

/// Optional capability kept separate so lightweight test repositories only
/// need to implement current conditions.
abstract interface class HourlyWeatherRepository {
  Future<List<HourlyWeatherData>> fetchHourly(
    SavedLocation location,
    DateTime localDate,
  );
}
