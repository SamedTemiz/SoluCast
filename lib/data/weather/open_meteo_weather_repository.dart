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
class OpenMeteoWeatherRepository
    implements
        WeatherRepository,
        RefreshableWeatherRepository,
        HourlyWeatherRepository {
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
  Future<WeatherData?> fetchCurrent(SavedLocation location) =>
      _fetchCurrent(location, forceRefresh: false);

  @override
  Future<bool> refreshCurrent(SavedLocation location) async {
    final result = await _fetchCurrent(location, forceRefresh: true);
    // `_fetchCurrent` deliberately falls back to stale cache on failure. Only
    // an item fetched just now proves that the network refresh succeeded.
    return result != null &&
        DateTime.now().toUtc().difference(result.fetchedAt) <
            const Duration(seconds: 5);
  }

  Future<WeatherData?> _fetchCurrent(
    SavedLocation location, {
    required bool forceRefresh,
  }) async {
    final cached = _readCache(location);
    if (!forceRefresh &&
        cached != null &&
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

  @override
  Future<List<HourlyWeatherData>> fetchHourly(
    SavedLocation location,
    DateTime localDate,
  ) async {
    final date =
        '${localDate.year.toString().padLeft(4, '0')}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
    try {
      final uri = Uri.https(_host, '/v1/forecast', {
        'latitude': location.latitude.toString(),
        'longitude': location.longitude.toString(),
        'hourly':
            'temperature_2m,wind_speed_10m,precipitation_probability,weather_code',
        'start_date': date,
        'end_date': date,
        'timezone': location.timeZoneId,
      });
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return const [];
      return parseHourlyResponse(response.body);
    } catch (_) {
      return const [];
    }
  }

  static List<HourlyWeatherData> parseHourlyResponse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final hourly = json['hourly'] as Map<String, dynamic>;
      final times = hourly['time'] as List;
      final temperatures = hourly['temperature_2m'] as List;
      final winds = hourly['wind_speed_10m'] as List;
      final precipitation = hourly['precipitation_probability'] as List;
      final codes = hourly['weather_code'] as List;
      final count = [
        times.length,
        temperatures.length,
        winds.length,
        precipitation.length,
        codes.length,
      ].reduce((a, b) => a < b ? a : b);
      return List.generate(
        count,
        (index) => HourlyWeatherData(
          localTime: DateTime.parse(times[index] as String),
          temperatureC: (temperatures[index] as num).toDouble(),
          windSpeedKmh: (winds[index] as num).toDouble(),
          precipitationProbabilityPct:
              (precipitation[index] as num?)?.toInt() ?? 0,
          weatherCode: (codes[index] as num).toInt(),
        ),
      );
    } catch (_) {
      return const [];
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
      final precipProbs =
          (hourly['precipitation_probability'] as List?)
              ?.map((e) => (e as num?)?.toInt() ?? 0)
              .toList() ??
          const <int>[];

      return WeatherData(
        temperatureC: (current['temperature_2m'] as num).toDouble(),
        windSpeedKmh: (current['wind_speed_10m'] as num).toDouble(),
        windDirectionDeg: (current['wind_direction_10m'] as num).toInt(),
        cloudCoverPct: (current['cloud_cover'] as num).toInt(),
        precipitationProbabilityPct: precipProbs.isNotEmpty
            ? precipProbs.last
            : 0,
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
