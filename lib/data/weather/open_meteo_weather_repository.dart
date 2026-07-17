import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../location/saved_location.dart';
import 'weather_data.dart';
import 'weather_repository.dart';

/// Open-Meteo tabanlı [WeatherRepository].
///
/// - Geliştirmede ücretsiz uç (`api.open-meteo.com`); yayında ticari uca ve
///   OpenWeatherMap yedeğine geçiş bu sınıfı değiştirmekle sınırlı (arayüz sabit).
/// - 1 saat TTL cache (shared_preferences) → çağrı bütçesini korur (data-sources.md).
/// - Ağ hatasında **eski cache** döner (offline fallback, F3.3); hiç veri yoksa null.
///
/// [client] test için enjekte edilebilir (gerçek ağ olmadan parse doğrulaması).
class OpenMeteoWeatherRepository implements WeatherRepository {
  OpenMeteoWeatherRepository({
    required this.prefs,
    http.Client? client,
    this.ttl = const Duration(hours: 1),
  }) : _client = client ?? http.Client();

  final SharedPreferences prefs;
  final http.Client _client;
  final Duration ttl;

  static const _host = 'api.open-meteo.com';

  @override
  Future<WeatherData?> fetchCurrent(SavedLocation location) async {
    final cached = _readCache(location);
    if (cached != null &&
        DateTime.now().toUtc().difference(cached.fetchedAt) < ttl) {
      return cached; // taze cache → ağ yok
    }

    try {
      final uri = Uri.https(_host, '/v1/forecast', {
        'latitude': location.latitude.toString(),
        'longitude': location.longitude.toString(),
        'current':
            'temperature_2m,wind_speed_10m,wind_direction_10m,cloud_cover,surface_pressure',
        'hourly': 'pressure_msl,precipitation_probability',
        'past_hours': '3',
        'forecast_hours': '1',
        'timezone': 'UTC',
      });
      final resp = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return cached;

      final data = parseResponse(resp.body);
      if (data != null) _writeCache(location, data);
      return data ?? cached;
    } catch (_) {
      return cached; // offline / timeout → eldeki cache (varsa)
    }
  }

  /// HTTP gövdesini [WeatherData]'ya çevirir (saf; testte doğrudan çağrılır).
  static WeatherData? parseResponse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final current = json['current'] as Map<String, dynamic>;
      final hourly = json['hourly'] as Map<String, dynamic>;

      final pressures = (hourly['pressure_msl'] as List)
          .whereType<num>()
          .map((e) => e.toDouble())
          .toList();
      final precipProbs = (hourly['precipitation_probability'] as List?)
              ?.map((e) => (e as num?)?.toInt() ?? 0)
              .toList() ??
          const <int>[];

      return WeatherData(
        temperatureC: (current['temperature_2m'] as num).toDouble(),
        windSpeedKmh: (current['wind_speed_10m'] as num).toDouble(),
        windDirectionDeg: (current['wind_direction_10m'] as num).toInt(),
        cloudCoverPct: (current['cloud_cover'] as num).toInt(),
        precipitationProbabilityPct:
            precipProbs.isNotEmpty ? precipProbs.last : 0,
        pressureHpa: (current['surface_pressure'] as num).toDouble(),
        pressureTrend: classifyPressureTrend(pressures),
        fetchedAt: DateTime.now().toUtc(),
      );
    } catch (_) {
      return null;
    }
  }

  String _cacheKey(SavedLocation l) =>
      'weather_${l.latitude.toStringAsFixed(3)}_${l.longitude.toStringAsFixed(3)}';

  WeatherData? _readCache(SavedLocation location) {
    final raw = prefs.getString(_cacheKey(location));
    if (raw == null) return null;
    try {
      return WeatherData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  void _writeCache(SavedLocation location, WeatherData data) {
    prefs.setString(_cacheKey(location), jsonEncode(data.toJson()));
  }
}
