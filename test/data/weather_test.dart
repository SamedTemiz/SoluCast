import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solucast/core/core.dart';
import 'package:solucast/data/location/saved_location.dart';
import 'package:solucast/data/weather/open_meteo_weather_repository.dart';
import 'package:solucast/data/weather/weather_data.dart';

void main() {
  group('classifyPressureTrend (F3.2)', () {
    test('3 saatte -4 hPa → fallingFast (cephe geliyor, aktivite ↑)', () {
      expect(classifyPressureTrend([1016, 1014, 1012]),
          PressureTrend.fallingFast);
    });
    test('hafif düşüş (-1.5 hPa) → falling', () {
      expect(classifyPressureTrend([1015, 1013.5]), PressureTrend.falling);
    });
    test('sabit → steady', () {
      expect(classifyPressureTrend([1015, 1015.3]), PressureTrend.steady);
    });
    test('hızlı yükseliş → risingFast', () {
      expect(classifyPressureTrend([1010, 1014]), PressureTrend.risingFast);
    });
    test('tek/boş okuma → steady (güvenli varsayılan)', () {
      expect(classifyPressureTrend([1015]), PressureTrend.steady);
      expect(classifyPressureTrend([]), PressureTrend.steady);
    });
  });

  group('parseResponse', () {
    test('geçerli Open-Meteo yanıtını doğru çözer', () {
      final body = jsonEncode({
        'current': {
          'temperature_2m': 22.4,
          'wind_speed_10m': 12.0,
          'wind_direction_10m': 210,
          'cloud_cover': 40,
          'surface_pressure': 1012.3,
        },
        'hourly': {
          'pressure_msl': [1016.0, 1014.0, 1012.0, 1011.0],
          'precipitation_probability': [10, 20, 30, 35],
        },
      });
      final data = OpenMeteoWeatherRepository.parseResponse(body);
      expect(data, isNotNull);
      expect(data!.temperatureC, 22.4);
      expect(data.windDirectionDeg, 210);
      expect(data.precipitationProbabilityPct, 35); // son saat
      expect(data.pressureTrend, PressureTrend.fallingFast); // 1016→1011 = -5
    });

    test('bozuk gövde → null (çökmez)', () {
      expect(OpenMeteoWeatherRepository.parseResponse('not json'), isNull);
      expect(OpenMeteoWeatherRepository.parseResponse('{}'), isNull);
    });
  });

  group('fetchCurrent — cache + offline fallback', () {
    const loc = SavedLocation(
        name: 'T', latitude: 40, longitude: 29, timeZoneId: 'Europe/Istanbul');

    String okBody() => jsonEncode({
          'current': {
            'temperature_2m': 18.0,
            'wind_speed_10m': 8.0,
            'wind_direction_10m': 90,
            'cloud_cover': 20,
            'surface_pressure': 1013.0,
          },
          'hourly': {
            'pressure_msl': [1013.0, 1013.2],
            'precipitation_probability': [5],
          },
        });

    test('başarılı çağrı veriyi döndürür ve cache\'ler', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var calls = 0;
      final client = MockClient((req) async {
        calls++;
        return http.Response(okBody(), 200);
      });
      final repo = OpenMeteoWeatherRepository(prefs: prefs, client: client);

      final first = await repo.fetchCurrent(loc);
      expect(first, isNotNull);
      expect(first!.temperatureC, 18.0);
      expect(calls, 1);

      // İkinci çağrı taze cache'ten gelmeli (ağ yok).
      final second = await repo.fetchCurrent(loc);
      expect(second, isNotNull);
      expect(calls, 1, reason: 'taze cache içindeyken tekrar ağ çağrısı olmamalı');
    });

    test('ağ hatasında eski cache döner (offline fallback, F3.3)', () async {
      // Önce cache'i dolu bırak.
      final seed = OpenMeteoWeatherRepository.parseResponse(okBody())!;
      SharedPreferences.setMockInitialValues({
        'weather_40.000_29.000': jsonEncode(seed.toJson()),
      });
      final prefs = await SharedPreferences.getInstance();
      // TTL=0 → cache bayat sayılır, ağ denenir; ağ patlar → cache döner.
      final failing = MockClient((req) async => throw Exception('offline'));
      final repo = OpenMeteoWeatherRepository(
          prefs: prefs, client: failing, ttl: Duration.zero);

      final result = await repo.fetchCurrent(loc);
      expect(result, isNotNull);
      expect(result!.temperatureC, 18.0, reason: 'bayat cache döndürülmeli');
    });

    test('cache yok + ağ hatası → null (uygulama astronomiyle devam)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final failing = MockClient((req) async => throw Exception('offline'));
      final repo = OpenMeteoWeatherRepository(prefs: prefs, client: failing);
      expect(await repo.fetchCurrent(loc), isNull);
    });
  });
}
