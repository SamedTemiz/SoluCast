import 'dart:convert';

import 'package:http/http.dart' as http;

import 'saved_location.dart';

/// Şehir/yer adıyla konum arama — **sağlayıcı-bağımsız** arayüz. Open-Meteo
/// Geocoding uç yanıtında IANA `timezone` alanı döndürür → DST doğru çözülür
/// (F1.2). Konum verisi cihazda kalır (F1.4).
abstract interface class GeocodingRepository {
  Future<List<SavedLocation>> search(String query);
}

class OpenMeteoGeocodingRepository implements GeocodingRepository {
  OpenMeteoGeocodingRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  static const _host = 'geocoding-api.open-meteo.com';

  @override
  Future<List<SavedLocation>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    try {
      final uri = Uri.https(_host, '/v1/search', {
        'name': q,
        'count': '8',
        'language': 'en',
        'format': 'json',
      });
      final resp = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return const [];
      return parseResults(resp.body);
    } catch (_) {
      return const [];
    }
  }

  /// HTTP gövdesini konum listesine çevirir (saf; testte doğrudan çağrılır).
  static List<SavedLocation> parseResults(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final results = json['results'] as List?;
      if (results == null) return const [];
      return results
          .whereType<Map<String, dynamic>>()
          .where((r) => r['timezone'] != null) // tz olmadan hesap yapılamaz
          .map((r) {
            final name = r['name'] as String;
            final admin1 = r['admin1'] as String?;
            final country = r['country'] as String?;
            // Aynı isimli yerleri ayırt et: "Trabzon, Turkey".
            final label = [
              name,
              admin1 ?? country,
            ].where((s) => s != null && s.isNotEmpty).join(', ');
            return SavedLocation(
              name: label,
              latitude: (r['latitude'] as num).toDouble(),
              longitude: (r['longitude'] as num).toDouble(),
              timeZoneId: r['timezone'] as String,
            );
          })
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
