import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:solucast/data/location/geocoding_repository.dart';

void main() {
  group('parseResults', () {
    test('geçerli Open-Meteo yanıtından konum + IANA tz çıkarır', () {
      final body = jsonEncode({
        'results': [
          {
            'name': 'Trabzon',
            'latitude': 41.0,
            'longitude': 39.72,
            'timezone': 'Europe/Istanbul',
            'country': 'Turkey',
            'admin1': 'Trabzon',
          },
          {
            'name': 'Sydney',
            'latitude': -33.87,
            'longitude': 151.21,
            'timezone': 'Australia/Sydney',
            'country': 'Australia',
            'admin1': 'New South Wales',
          },
        ],
      });
      final results = OpenMeteoGeocodingRepository.parseResults(body);
      expect(results, hasLength(2));
      expect(results[0].name, 'Trabzon, Trabzon');
      expect(results[0].timeZoneId, 'Europe/Istanbul');
      expect(results[1].latitude, -33.87);
      expect(results[1].timeZoneId, 'Australia/Sydney');
    });

    test('timezone alanı olmayan sonuç elenir (hesap yapılamaz)', () {
      final body = jsonEncode({
        'results': [
          {'name': 'Nowhere', 'latitude': 0, 'longitude': 0},
        ],
      });
      expect(OpenMeteoGeocodingRepository.parseResults(body), isEmpty);
    });

    test('sonuç yok / bozuk gövde → boş liste (çökmez)', () {
      expect(OpenMeteoGeocodingRepository.parseResults('{}'), isEmpty);
      expect(OpenMeteoGeocodingRepository.parseResults('bad'), isEmpty);
    });
  });

  group('search', () {
    test('2 harften kısa sorgu ağ çağrısı yapmadan boş döner', () async {
      var called = false;
      final client = MockClient((req) async {
        called = true;
        return http.Response('{}', 200);
      });
      final repo = OpenMeteoGeocodingRepository(client: client);
      expect(await repo.search('a'), isEmpty);
      expect(called, isFalse);
    });

    test('ağ hatasında boş liste döner (çökmez)', () async {
      final client = MockClient((req) async => throw Exception('offline'));
      final repo = OpenMeteoGeocodingRepository(client: client);
      expect(await repo.search('Trabzon'), isEmpty);
    });
  });
}
